module Access
  class MigrateService < BaseService
    def self.migrate_user!(user)
      church = Church.find(user[:church_id])
      ProvisionService.call(church: church) unless church.profiles_provisioned_at?
      membership = church.church_memberships.find_or_create_by!(user: user) do |link|
        link.active = user.deleted_at.nil?
        link.access_enabled = user.encrypted_password.present?
      end
      return membership if membership.profile_assignments.exists?
      key = user.role == "co_pastor" ? "pastor" : user.role
      profile = church.access_profiles.find_by!(key: key.presence || "member")
      membership.profile_assignments.create!(church: church, access_profile: profile)
      Audit::RecordService.call(church: church, user: user, module_key: "access", action: "Migrou perfil de acesso",
                                detail: "#{user.role} → #{profile.key}")
      membership
    end

    def initialize(church:)
      @church = church
    end

    def call
      @church.with_lock do
        ProvisionService.call(church: @church)
        # Existing explicit menu settings become explicit read grants. No implicit allow.
        @church.role_permissions.where(access_profile_id: nil).find_each do |legacy|
          profile = @church.access_profiles.find_by!(key: legacy.role)
          profile.role_permissions.find_or_initialize_by(module_key: legacy.module_key, action_key: "read").tap do |permission|
            permission.assign_attributes(church: @church, allowed: legacy.allowed, scope_key: permission.scope_key || "church")
            permission.save!
          end
          legacy.destroy!
        end
        User.where(church_id: @church.id).find_each { |user| self.class.migrate_user!(user) }
      end
      Success(true)
    end
  end
end
