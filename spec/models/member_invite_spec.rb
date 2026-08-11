require "rails_helper"

RSpec.describe MemberInvite, type: :model do
  let!(:church) { Church.create!(name: "Test Church", slug: "test-church") }
  let!(:admin) do
    User.create!(name: "Secretaria", email: "secretaria@test.com", phone: "(11) 91111-1111",
                 password: "password123", password_confirmation: "password123", church: church, role: :admin)
  end

  def build_invite(**overrides)
    church.member_invites.build({ created_by: admin, max_uses: 5, expires_at: 7.days.from_now }.merge(overrides))
  end

  it "generates a unique token before create" do
    invite = build_invite
    invite.save!

    expect(invite.token).to be_present
  end

  it "requires expires_at" do
    invite = build_invite(expires_at: nil)

    expect(invite.save).to be false
    expect(invite.errors[:expires_at]).to be_present
  end

  it "rejects max_uses above 500" do
    invite = build_invite(max_uses: 501)

    expect(invite.save).to be false
  end

  describe "#usable?" do
    it "is usable while active, not expired and under the uses limit" do
      invite = build_invite.tap(&:save!)

      expect(invite.usable?).to be true
    end

    it "is not usable once expired" do
      invite = build_invite(expires_at: 1.hour.ago).tap { |i| i.save!(validate: false) }

      expect(invite.usable?).to be false
    end

    it "is not usable once uses_count reaches max_uses" do
      invite = build_invite(max_uses: 1).tap(&:save!)
      invite.use!

      expect(invite.usable?).to be false
      expect(invite).to be_exhausted
    end
  end

  describe "#deactivate!" do
    it "marks the invite as deactivated" do
      invite = build_invite.tap(&:save!)
      invite.deactivate!

      expect(invite).to be_deactivated
      expect(invite.usable?).to be false
    end
  end

  describe "#remaining_uses" do
    it "subtracts uses_count from max_uses" do
      invite = build_invite(max_uses: 5).tap(&:save!)
      invite.use!

      expect(invite.remaining_uses).to eq(4)
    end
  end
end
