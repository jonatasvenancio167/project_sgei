require "rails_helper"

RSpec.describe "Concurrent administrator revocation" do
  self.use_transactional_tests = false

  it "serializes two revocations and preserves one active administrator" do
    church = Church.create!(name: "Concurrency", slug: "concurrency-#{SecureRandom.hex(6)}")
    admins = 2.times.map do |index|
      User.create!(church: church, name: "Admin #{index}", role: :admin, phone: "(11) 91111-1111",
        email: "concurrent-#{SecureRandom.hex(6)}@test.com", password: "password123")
    end
    start = Queue.new
    results = Queue.new
    threads = admins.map do |admin|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          start.pop
          begin
            User.find(admin.id).update!(status: :inactive)
            results << :revoked
          rescue ActiveRecord::RecordInvalid
            results << :blocked
          end
        end
      end
    end
    2.times { start << true }
    threads.each(&:join)
    expect(2.times.map { results.pop }).to contain_exactly(:revoked, :blocked)
    expect(Access::Integrity.administrators(church).size).to eq(1)
  ensure
    threads&.each { |thread| thread.join if thread.alive? }
    if church&.persisted?
      AuditLog.where(church_id: church.id).delete_all
      ProfileAssignment.where(church_id: church.id).delete_all
      ChurchMembership.where(church_id: church.id).delete_all
      RolePermission.where(church_id: church.id).delete_all
      AccessProfile.where(church_id: church.id).delete_all
      User.where(church_id: church.id).delete_all
      Church.where(id: church.id).delete_all
    end
  end
end
