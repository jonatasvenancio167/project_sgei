require "rails_helper"

RSpec.describe "Access profile integrity" do
  let!(:church) { Church.create!(name: "Test", slug: "test") }
  let!(:admin) { create_user("admin", role: :admin) }
  let!(:member) { create_user("member") }

  def create_user(name, role: :member)
    User.create!(church: church, name: name, email: "#{name}@test.com", phone: "(11) 91111-1111", password: "password123", role: role)
  end

  def profile(key) = church.access_profiles.find_by!(key: key)
  def assign(user, key)
    user.church_memberships.find_by!(church: church).profile_assignments.find_or_create_by!(church: church, access_profile: profile(key))
  end

  it "provisions idempotently and preserves local changes" do
    permission = profile("member").permission("events", "read")
    permission.update!(allowed: false)
    counts = [ AccessProfile.count, RolePermission.count, ProfileAssignment.count ]
    2.times { Access::MigrateService.call(church: church) }
    expect([ AccessProfile.count, RolePermission.count, ProfileAssignment.count ]).to eq(counts)
    expect(permission.reload).not_to be_allowed
  end

  it "enforces normalized uniqueness at database level, independently per church" do
    duplicate = AccessProfile.new(church: church, key: "duplicate", name: "  SECRETÁRIA ", description: "Outro")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:normalized_name]).to be_present
    expect {
      AccessProfile.transaction(requires_new: true) do
        AccessProfile.insert_all!([ { church_id: church.id, key: "duplicate", name: "SECRETÁRIA", normalized_name: "secretaria", description: "Outro", created_at: Time.current, updated_at: Time.current } ])
      end
    }.to raise_error(ActiveRecord::RecordNotUnique)
    other = Church.create!(name: "Other", slug: "other")
    expect(other.access_profiles.find_by!(key: "secretary").normalized_name).to eq("secretaria")
  end

  it "combines profiles and revokes only the removed grant" do
    assignment = assign(member, "volunteer")
    assign(member, "secretary")
    expect(member.can_access?("welcome", action: "manage")).to be true
    assignment.destroy!
    expect(member.can_access?("welcome", action: "manage")).to be true
    expect(member.can_access?("access", action: "manage")).to be false
  end

  it "does not infer global access from organizational leadership" do
    dept = church.departaments.create!(name: "Mídia")
    member.memberchips.create!(departament: dept, role: :leader)
    expect(member.can_access?("departments", action: "manage", record: dept)).to be false
    assign(member, "leader")
    expect(member.can_access?("departments", action: "manage", record: dept)).to be true
    other = church.departaments.create!(name: "Louvor")
    expect(member.can_access?("departments", action: "manage", record: other)).to be false
    member.memberchips.find_by!(departament: dept).update!(role: :member)
    expect(member.can_access?("departments", action: "manage", record: dept)).to be false
  end

  it "allows members to read only themselves and published events" do
    expect(UserPolicy::Scope.new(member, User).resolve.pluck(:id)).to eq([ member.id ])
    expect(UserPolicy.new(member, admin).show?).to be false
    event = church.events.create!(title: "Culto", location: "Sede", start_date: Date.current, end_date: Date.current, status: :draft, visibility: :public_event)
    expect(EventPolicy.new(member, event).show?).to be false
    event.update!(status: :approved)
    expect(EventPolicy.new(member, event).show?).to be true
  end

  it "keeps finance and pastoral away from access administration" do
    %w[finance pastor].each do |key|
      assign(member, key)
      expect(member.can_access?("access", action: "manage")).to be false
      expect(member.can_access?("settings", action: "manage")).to be false
    end
  end

  it "rejects leader assignment without an explicit ministry and rolls back creation" do
    result = Access::MemberSaveService.call(church: church, performed_by: admin,
      params: { name: "Sem equipe", phone: "(11) 93333-3333", access_profile_ids: [ profile("leader").id ] })
    expect(result).to be_failure
    expect(User.exists?(name: "Sem equipe")).to be false
  end

  it "prevents secretary from assigning privileged profiles" do
    assign(member, "secretary")
    expect {
      Access::MemberSaveService.call(church: church, performed_by: member,
        params: { name: "Invasor", phone: "(11) 93333-3333", access_profile_ids: [ profile("admin").id ] })
    }.to raise_error(Pundit::NotAuthorizedError)
  end

  it "preserves profiles when a secretary edits member data" do
    secretary = create_user("secretary")
    assign(secretary, "secretary")
    before = member.church_memberships.first.access_profiles.pluck(:id)
    result = Access::MemberSaveService.call(church: church, performed_by: secretary, user: member, params: { name: "Atualizado" })
    expect(result).to be_success
    expect(member.church_memberships.first.access_profiles.pluck(:id)).to eq(before)
  end

  it "blocks self elevation through a profile inherited by the actor" do
    assign(member, "volunteer")
    profile("volunteer").role_permissions.create!(church: church, module_key: "access", action_key: "manage", scope_key: "church", allowed: true)
    permissions = { "settings" => { "manage" => "1", "read" => "1", "manage_scope" => "church", "read_scope" => "church" } }
    result = Settings::PermissionUpdateService.call(church: church, profile: profile("member"), performed_by: member, permissions: permissions)
    expect(result).to be_failure
    expect(profile("member").permission("settings", "manage")).to be_nil
  end

  it "protects the last administrator from deactivation, deletion and revocation" do
    expect { admin.update!(status: :inactive) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(admin.reload.status).to eq("active")
    membership = admin.church_memberships.first
    expect { membership.update!(access_enabled: false) }.to raise_error(Access::Integrity::Violation)
    expect { membership.profile_assignments.first.destroy! }.to raise_error(Access::Integrity::Violation)
    expect(Access::Integrity.administrators(church).size).to eq(1)
  end

  it "allows revocation when another active administrator remains" do
    assign(member, "admin")
    expect(admin.update(status: :inactive)).to be true
    expect(Access::Integrity.administrators(church).map(&:user_id)).to eq([ member.id ])
  end

  it "rejects cross-tenant assignments at the model and database boundaries" do
    other = Church.create!(name: "Other", slug: "other")
    assignment = ProfileAssignment.new(church: church, church_membership: member.church_memberships.first, access_profile: other.access_profiles.first)
    expect(assignment).not_to be_valid
    expect {
      ProfileAssignment.transaction(requires_new: true) { assignment.save!(validate: false) }
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "preserves hierarchy reads without allowing writes in daughter churches" do
    child = church.congregations.create!(name: "Filha", slug: "child")
    child_member = User.create!(church: child, name: "Filha", email: "child@test.com", phone: "(11) 91111-1111")
    expect(UserPolicy.new(admin, child_member).show?).to be true
    expect(UserPolicy.new(admin, child_member).update?).to be false
  end
  it "revokes membership access without changing another church's grants" do
    other = Church.create!(name: "Other", slug: "other")
    link = member.church_memberships.create!(church: other, active: true, access_enabled: true)
    link.profile_assignments.create!(church: other, access_profile: other.access_profiles.find_by!(key: "member"))
    result = Settings::UserRemoveService.call(user: member, performed_by: admin)
    expect(result).to be_success
    expect(member.church_memberships.find_by!(church: church)).not_to be_active
    expect(link.reload).to be_active
    expect(link).to be_access_enabled
    expect(Access::PermissionQuery.new(user: member, church: other).allowed?("events")).to be true
  end

  it "does not accept privileged profile IDs from another tenant" do
    other = Church.create!(name: "Other", slug: "other")
    expect {
      Access::MemberSaveService.call(church: church, performed_by: admin, user: member,
        params: { access_profile_ids: [ other.access_profiles.find_by!(key: "admin").id ] })
    }.to raise_error(Pundit::NotAuthorizedError)
    expect(member.church_memberships.find_by!(church: church).access_profiles.pluck(:key)).to eq([ "member" ])
  end

  it "blocks role assignment to the acting user" do
    assign(member, "volunteer")
    profile("volunteer").role_permissions.create!(church: church, module_key: "access", action_key: "manage", scope_key: "church", allowed: true)
    result = Access::MemberSaveService.call(church: church, performed_by: member, user: member,
      params: { access_profile_ids: [ profile("admin").id ] })
    expect(result).to be_failure
    expect(member.reload.admin?).to be false
  end

  it "requires credentials before enabling access" do
    result = Access::MemberSaveService.call(church: church, performed_by: admin,
      params: { name: "Sem senha", phone: "(11) 93333-3333", access_enabled: "1" })
    expect(result).to be_failure
    expect(User.exists?(name: "Sem senha")).to be false
  end
  it "does not let a church administrator take over a shared user's credentials" do
    other = Church.create!(name: "Other", slug: "other")
    member.church_memberships.create!(church: other, active: true, access_enabled: true)
    expect {
      Access::MemberSaveService.call(church: church, performed_by: admin, user: member,
        params: { email: "takeover@test.com", access_enabled: "1", password: "different123" })
    }.to raise_error(Pundit::NotAuthorizedError)
    expect(member.reload.email).to eq("member@test.com")
    expect(member.valid_password?("password123")).to be true
  end
end
