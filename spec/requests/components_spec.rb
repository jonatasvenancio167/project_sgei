require 'rails_helper'

RSpec.describe "Components", type: :request do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:user) { User.create!(name: "Test Admin", email: "admin@test.com", password: "password123", password_confirmation: "password123", church: church, role: :admin) }

  before do
    sign_in user
  end

  describe "GET /index" do
    it "returns http success" do
      get "/components/index"
      expect(response).to have_http_status(:success)
    end
  end

end
