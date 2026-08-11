require "rails_helper"

RSpec.describe "Member invites", type: :request do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:admin) do
    User.create!(name: "Secretaria", email: "secretaria@test.com", phone: "(11) 91111-1111",
                 password: "password123", password_confirmation: "password123", church: church, role: :admin)
  end
  let!(:member) do
    User.create!(name: "Regular Member", email: "member@test.com", phone: "(11) 92222-2222",
                 password: "password123", password_confirmation: "password123", church: church, role: :member)
  end

  describe "POST /panel/members/invites" do
    before { sign_in admin }

    it "generates an invite link for the secretary" do
      expect {
        post "/panel/members/invites", params: { member_invite: { expires_in: "7_days", max_uses: 5, note: "Retiro" } }
      }.to change(MemberInvite, :count).by(1)

      invite = MemberInvite.last
      expect(invite.church).to eq(church)
      expect(invite.created_by).to eq(admin)
      expect(invite.max_uses).to eq(5)
      expect(response).to redirect_to(panel_member_invites_path)
    end

    it "is forbidden for a plain member" do
      sign_out admin
      sign_in member

      post "/panel/members/invites", params: { member_invite: { expires_in: "7_days", max_uses: 5 } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /panel/members/invites/:id" do
    let!(:invite) { church.member_invites.create!(created_by: admin, max_uses: 5, expires_at: 7.days.from_now) }

    it "deactivates the invite" do
      sign_in admin

      delete "/panel/members/invites/#{invite.id}"

      expect(invite.reload).to be_deactivated
      expect(response).to redirect_to(panel_member_invites_path)
    end
  end

  describe "GET /i/:token" do
    let!(:invite) { church.member_invites.create!(created_by: admin, max_uses: 5, expires_at: 7.days.from_now) }

    it "renders the public registration form for a usable invite" do
      get "/i/#{invite.token}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(church.name)
    end

    it "renders not found for an unknown token" do
      get "/i/does-not-exist"

      expect(response).to have_http_status(:not_found)
    end

    it "renders not found for an expired invite" do
      expired = church.member_invites.create!(created_by: admin, max_uses: 5, expires_at: 7.days.from_now)
      expired.update_columns(expires_at: 1.hour.ago)

      get "/i/#{expired.token}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /i/:token" do
    let!(:invite) { church.member_invites.create!(created_by: admin, max_uses: 1, expires_at: 7.days.from_now) }

    it "creates a pending member and consumes the invite" do
      expect {
        post "/i/#{invite.token}", params: { user: { name: "Novo Membro", phone: "(11) 91111-1111" } }
      }.to change(User, :count).by(1)

      new_user = User.find_by(name: "Novo Membro")
      expect(new_user.status).to eq("pending")
      expect(new_user.church).to eq(church)
      expect(invite.reload).to be_exhausted
      expect(response).to redirect_to(public_member_invite_success_path(invite.token))
    end

    it "re-renders the form when required fields are missing" do
      post "/i/#{invite.token}", params: { user: { name: "", phone: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects submissions once the invite is exhausted" do
      invite.use!

      post "/i/#{invite.token}", params: { user: { name: "Outro", phone: "(11) 92222-2222" } }

      expect(response).to have_http_status(:not_found)
    end
  end
end
