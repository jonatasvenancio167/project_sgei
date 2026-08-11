require "rails_helper"

RSpec.describe "Member registration approvals", type: :request do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:admin) do
    User.create!(name: "Secretaria", email: "secretaria@test.com", phone: "(11) 91111-1111",
                 password: "password123", password_confirmation: "password123", church: church, role: :admin)
  end
  let!(:leader) do
    User.create!(name: "Lider", email: "leader@test.com", phone: "(11) 93333-3333",
                 password: "password123", password_confirmation: "password123", church: church, role: :leader)
  end
  let!(:pending_user) do
    User.create!(name: "Pendente", email: "pendente@test.com", phone: "(11) 91111-1111",
                 password: "password123", password_confirmation: "password123",
                 church: church, role: :member, status: :pending)
  end

  describe "POST /users/:user_id/approval" do
    it "activates a pending member when performed by the secretary" do
      sign_in admin

      post "/users/#{pending_user.id}/approval"

      expect(pending_user.reload.status).to eq("active")
      expect(response).to redirect_to(panel_members_path)
    end

    it "is forbidden for a leader" do
      sign_in leader

      post "/users/#{pending_user.id}/approval"

      expect(pending_user.reload.status).to eq("pending")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /users/:user_id/rejection" do
    it "marks the registration as inactive with a reason" do
      sign_in admin

      post "/users/#{pending_user.id}/rejection", params: { reason: "Dados incompletos" }

      expect(pending_user.reload.status).to eq("inactive")
      expect(response).to redirect_to(panel_members_path)
    end
  end
end
