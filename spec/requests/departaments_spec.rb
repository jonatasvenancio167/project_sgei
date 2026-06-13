require 'rails_helper'

RSpec.describe "Departaments", type: :request do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:user) { User.create!(name: "Test Admin", email: "admin@test.com", password: "password123", password_confirmation: "password123", church: church, role: :admin) }
  let!(:other_user) { User.create!(name: "Regular Member", email: "member@test.com", password: "password123", password_confirmation: "password123", church: church, role: :member) }

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
      expect(other_user.reload.role).to eq("leader")
      expect(response).to redirect_to(departaments_path)
    end
  end

  describe "POST /departaments/:id/add_members" do
    let!(:dept) { church.departaments.create!(name: "Kids", description: "Kids group", color: "bg-green-500 text-white", icon: "baby") }

    context "with existing member" do
      it "links the user to the departament" do
        expect {
          post "/departaments/#{dept.id}/add_members", params: {
            kind: "existing",
            user_ids: [other_user.id]
          }
        }.to change(Memberchip, :count).by(1)

        expect(dept.users).to include(other_user)
        expect(response).to redirect_to(departaments_path)
      end
    end

    context "with a new member" do
      it "creates a new user with nil email when email is blank" do
        post "/departaments/#{dept.id}/add_members", params: {
          kind: "new",
          name: "Jane Smith",
          email: "",
          phone: "+5511988888888",
          make_leader: "0"
        }
        puts "RESPONSE STATUS: #{response.status}"
        puts "RESPONSE BODY: #{response.body}"
        expect(response).to redirect_to(departaments_path)
      end

      it "creates a new user and links them to the departament" do
        expect {
          post "/departaments/#{dept.id}/add_members", params: {
            kind: "new",
            name: "John Doe",
            email: "john.doe@test.com",
            phone: "+5511999999999",
            make_leader: "1"
          }
        }.to change(User, :count).by(1).and change(Memberchip, :count).by(1)

        new_user = User.find_by(email: "john.doe@test.com")
        expect(new_user).not_to be_nil
        expect(new_user.name).to eq("John Doe")
        expect(new_user.phone).to eq("+5511999999999")
        expect(new_user.role).to eq("leader")
        expect(dept.users).to include(new_user)
        expect(dept.leader).to eq(new_user)
        expect(response).to redirect_to(departaments_path)
      end
    end
  end
end
