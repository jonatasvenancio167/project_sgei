require 'rails_helper'

RSpec.describe "Departaments", type: :request do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:user) { User.create!(name: "Test Admin", email: "admin@test.com", phone: "(11) 91111-1111", password: "password123", password_confirmation: "password123", church: church, role: :admin) }
  let!(:other_user) { User.create!(name: "Regular Member", email: "member@test.com", phone: "(11) 92222-2222", password: "password123", password_confirmation: "password123", church: church, role: :member) }

  before do
    sign_in user
  end

  describe "GET /departaments" do
    it "returns success and lists departaments of the church" do
      dept = church.departaments.create!(name: "Youth", description: "Youth department", color: "bg-blue-500 text-white", icon: "users")
      
      get "/departaments"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Youth")
    end
  end

  describe "POST /departaments" do
    it "creates a new departament with members and leader" do
      expect {
        post "/departaments", params: {
          departament: {
            name: "Louvor",
            description: "Worship department",
            color: "bg-red-500 text-white",
            icon: "music"
          },
          member_ids: [other_user.id],
          leader_id: other_user.id
        }
      }.to change(Departament, :count).by(1)

      dept = Departament.last
      expect(dept.name).to eq("Louvor")
      expect(dept.color).to eq("bg-red-500 text-white")
      expect(dept.icon).to eq("music")
      expect(dept.leader).to eq(other_user)
      expect(other_user.reload.role).to eq("member")
      expect(other_user.access_profiles.pluck(:key)).to eq(["member"])
      expect(response).to redirect_to(departaments_path)
    end
  end

  describe "POST /departaments/:departament_id/members" do
    let!(:dept) { church.departaments.create!(name: "Kids", description: "Kids group", color: "bg-green-500 text-white", icon: "baby") }

    context "with existing member" do
      it "links the user to the departament" do
        expect {
          post "/departaments/#{dept.id}/members", params: {
            kind: "existing",
            user_ids: [other_user.id]
          }
        }.to change(Memberchip, :count).by(1)

        expect(dept.users).to include(other_user)
        expect(response).to redirect_to(departaments_path)
      end
    end

    context "with a new member" do
      it "creates and links a new user when email is blank" do
        post "/departaments/#{dept.id}/members", params: {
          kind: "new",
          name: "Jane Smith",
          email: "",
          phone: "(11) 98888-8888",
          make_leader: "0"
        }
        new_user = User.find_by!(name: "Jane Smith")
        expect(new_user.email).to match(/\Asem-email-[0-9a-f]+@ekklesia\.local\z/)
        expect(dept.users).to include(new_user)
        expect(response).to redirect_to(departaments_path)
      end

      it "creates a new user and links them to the departament" do
        expect {
          post "/departaments/#{dept.id}/members", params: {
            kind: "new",
            name: "John Doe",
            email: "john.doe@test.com",
            phone: "(11) 99999-9999",
            make_leader: "1"
          }
        }.to change(User, :count).by(1).and change(Memberchip, :count).by(1)

        new_user = User.find_by(email: "john.doe@test.com")
        expect(new_user).not_to be_nil
        expect(new_user.name).to eq("John Doe")
        expect(new_user.phone).to eq("(11) 99999-9999")
        expect(new_user.role).to eq("member")
        expect(new_user.access_profiles).to be_empty
        expect(new_user.encrypted_password).to be_empty
        expect(dept.users).to include(new_user)
        expect(dept.leader).to eq(new_user)
        expect(response).to redirect_to(departaments_path)
      end
    end
  end
end
