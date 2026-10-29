module Access
  class PermissionQuery
    def initialize(user:, church: user.church)
      @user, @church = user, church
    end

    def profiles
      membership = @user.church_memberships.find_by(church: @church, active: true, access_enabled: true)
      return AccessProfile.none unless membership && @user.status_active? && @user.deleted_at.nil?
      membership.access_profiles
    end

    def scopes(module_key, action: "read")
      profiles.includes(:role_permissions, parent_profile: :role_permissions).filter_map do |profile|
        permission = profile.permission(module_key, action)
        permission.scope_key if permission&.allowed?
      end.uniq
    end

    def allowed?(module_key, action: "read", record: nil)
      grants = scopes(module_key, action: action)
      return grants.any? if record.nil? || record.is_a?(Class) || record.is_a?(Symbol)
      if record.new_record?
        owner = if record.respond_to?(:church_id)
          record.church_id
        elsif record.respond_to?(:form) && record.form
          record.form.church_id
        elsif record.respond_to?(:event) && record.event
          record.event.church_id
        elsif record.respond_to?(:departament) && record.departament
          record.departament.church_id
        end
        return false unless owner == @church.id
        return true if grants.include?("church")
        if grants.include?("led") && record.respond_to?(:departament_id)
          return @user.memberchips.where(departament_id: record.departament_id, role: :leader).exists?
        end
        return grants.include?("own") && record.respond_to?(:user_id) && record.user_id == @user.id
      end
      ScopeQuery.new(user: @user, scope: record.class.where(id: record.id), module_key: module_key,
                     action: action, church: @church).call.exists?
    end
  end
end
