require "rails_helper"

RSpec.describe "Settings access profiles", type: :request do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:admin) do
    User.create!(name: "Administrador", email: "admin@test.com", phone: "(11) 91111-1111",
      password: "password123", password_confirmation: "password123", church: church, role: :admin)
  end
  let(:member_profile) { church.access_profiles.find_by!(key: "member") }
  let(:volunteer_profile) { church.access_profiles.find_by!(key: "volunteer") }
  before { sign_in admin }
  def document = Nokogiri::HTML(response.body)

  it "requires selection and offers seven profiles and profile creation" do
    get panel_settings_path(section: "permissions")
    expect(response).to have_http_status(:ok)
    expect(document.css('select[name="profile_id"] option').count).to eq(8)
    expect(document.css('form[action="/settings/permissions"]')).to be_empty
    expect(response.body).to include("Cadastrar perfil")
  end

  it "loads persisted and inherited permissions for the chosen profile" do
    get panel_settings_path(section: "permissions", profile_id: volunteer_profile.id)
    expect(response).to have_http_status(:ok)
    expect(document.at_css('input[name="permissions[events][read]"][type="checkbox"]')["checked"]).not_to be_nil
    expect(document.at_css('input[name="permissions[access][manage]"][type="checkbox"]')["checked"]).to be_nil
  end

  it "creates and selects a custom profile with base access only" do
    expect {
      post settings_access_profiles_path, params: { access_profile: { name: "Equipe de apoio", description: "Apoio aos eventos" } }
    }.to change(AccessProfile, :count).by(1)
    profile = church.access_profiles.find_by!(name: "Equipe de apoio")
    expect(profile.parent_profile).to eq(member_profile)
    expect(profile.permission("events", "read")).to be_allowed
    expect(profile.permission("access", "manage")).to be_nil
    expect(response).to redirect_to(panel_settings_path(section: "permissions", profile_id: profile.id))
  end

  it "rejects normalized duplicate names without losing the submitted data" do
    expect {
      post settings_access_profiles_path, params: { access_profile: { name: "  SeCRetÁria  ", description: "Duplicado" } }
    }.not_to change(AccessProfile, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Duplicado")
  end

  it "saves only the selected profile and records the change" do
    original = member_profile.role_permissions.pluck(:id, :allowed, :scope_key)
    expect {
      patch settings_permissions_path, params: { profile_id: volunteer_profile.id,
        permissions: { events: { read: "1", manage: "0", read_scope: "audience" } } }
    }.to change { church.audit_logs.where(module_key: "permissions").count }.by(1)
    expect(response).to redirect_to(panel_settings_path(section: "permissions", profile_id: volunteer_profile.id))
    expect(volunteer_profile.permission("events", "read")).to be_allowed
    expect(member_profile.role_permissions.pluck(:id, :allowed, :scope_key)).to eq(original)
  end

  it "does not accept another church's profile" do
    other = Church.create!(name: "Other", slug: "other")
    before = other.role_permissions.count
    patch settings_permissions_path, params: { profile_id: other.access_profiles.first.id, permissions: {} }
    expect(response).to have_http_status(:not_found)
    expect(other.role_permissions.count).to eq(before)
  end

  it "does not save without a selected profile" do
    patch settings_permissions_path, params: { permissions: {} }
    expect(response).to have_http_status(:not_found)
  end

  it "blocks removal of the last administrator's permissions" do
    profile = church.access_profiles.find_by!(key: "admin")
    patch settings_permissions_path, params: { profile_id: profile.id, permissions: {} }
    expect(response).to redirect_to(panel_settings_path(section: "permissions", profile_id: profile.id))
    expect(profile.permission("access", "manage")).to be_allowed
    expect(flash[:alert]).to include("administrador ativo")
  end

  it "blocks a member through HTML and JSON requests" do
    member = User.create!(name: "Membro", email: "member@test.com", phone: "(11) 92222-2222",
      password: "password123", church: church)
    sign_out admin
    sign_in member
    get panel_settings_path(section: "permissions")
    expect(response).to redirect_to(root_path)
    post settings_access_profiles_path(format: :json), params: { access_profile: { name: "Privilegiado", description: "Invasão" } }
    expect(response).to have_http_status(:forbidden)
  end

  it "creates a member without credentials and allows multiple explicit profiles" do
    post panel_members_create_path, params: { user: { name: "Novo", phone: "(11) 93333-3333",
      access_profile_ids: [ member_profile.id, volunteer_profile.id ] } }
    created = User.find_by!(name: "Novo")
    expect(created.encrypted_password).to be_empty
    expect(created.active_for_authentication?).to be false
    expect(created.church_memberships.first.access_profiles.pluck(:key)).to contain_exactly("member", "volunteer")
  end

  it "enables credentials only when explicitly requested" do
    post panel_members_create_path, params: { user: { name: "Com acesso", phone: "(11) 93333-3333",
      email: "access@test.com", access_enabled: "1", password: "password123", password_confirmation: "password123" } }
    created = User.find_by!(name: "Com acesso")
    expect(created.valid_password?("password123")).to be true
    expect(created.active_for_authentication?).to be true
  end

  it "switches only to an active church membership" do
    other = Church.create!(name: "Other", slug: "other")
    patch church_context_path, params: { church_id: other.id }
    expect(response).to have_http_status(:not_found)
    link = admin.church_memberships.create!(church: other, active: true, access_enabled: true)
    link.profile_assignments.create!(church: other, access_profile: other.access_profiles.find_by!(key: "member"))
    patch church_context_path, params: { church_id: other.id }
    expect(response).to redirect_to(root_path)
    get panel_settings_path(section: "permissions")
    expect(response).to redirect_to(root_path)
  end
  it "renders member and access forms with independent profile and organizational fields" do
    get panel_members_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Perfis de acesso", "Cargo ou função", "Habilitar acesso ao sistema", "Ministérios sob liderança")
    get panel_settings_path(section: "users")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Administrador da igreja", "Perfis de acesso")
  end

  it "signs out a session after its last enabled membership is revoked" do
    member = User.create!(name: "Membro", email: "session@test.com", phone: "(11) 92222-2222", password: "password123", church: church)
    sign_out admin
    sign_in member
    member.church_memberships.first.update!(access_enabled: false)
    get panel_members_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
