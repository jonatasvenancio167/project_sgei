module Access
  class Integrity
    class Violation < StandardError; end

    def self.administrators(church)
      memberships = church.church_memberships.where(active: true, access_enabled: true)
        .joins(:access_profiles, :user).where(access_profiles: { key: "admin" }, users: { status: 0, deleted_at: nil })
      memberships.distinct.select do |membership|
        PermissionQuery.new(user: membership.user, church: church).allowed?("access", action: "manage") &&
          PermissionQuery.new(user: membership.user, church: church).allowed?("settings", action: "manage")
      end
    end

    def self.guard_many(church_ids, &block)
      ids = church_ids.compact.uniq.sort
      return block.call if ids.empty?
      guard(Church.find(ids.first)) { guard_many(ids.drop(1), &block) }
    end

    def self.guard(church)
      church.with_lock do
        had_admin = administrators(church).any?
        result = yield
        if had_admin && administrators(church).empty?
          raise Violation, "A igreja deve manter pelo menos um administrador ativo com acesso habilitado"
        end
        result
      end
    end
  end
end
