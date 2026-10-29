module Settings
  class PermissionUpdateService < BaseService
    def initialize(church:, profile:, permissions:, performed_by:)
      @church, @profile, @permissions, @actor = church, profile, permissions.to_h, performed_by
    end

    def call
      raise Pundit::NotAuthorizedError unless @actor.church_id == @church.id && @actor.can_access?("access", action: "manage") && @profile.church_id == @church.id
      Access::Integrity.guard(@church) do
        before = fingerprint
        previous = @profile.role_permissions.map(&:attributes)
        RolePermission::MODULES.each_key do |mod|
          values = @permissions.fetch(mod, {}).to_h
          RolePermission::ACTIONS.each do |action|
            permission = @profile.role_permissions.find_or_initialize_by(module_key: mod, action_key: action)
            permission.church = @church
            permission.allowed = ActiveModel::Type::Boolean.new.cast(values[action]) || false
            permission.scope_key = values["#{action}_scope"].presence || permission.scope_key || "church"
            if action == "manage" && %w[hierarchy audience team].include?(permission.scope_key)
              raise Access::Integrity::Violation, "Alcance inválido para gerenciamento"
            end
            permission.save!
          end
        end
        raise Access::Integrity::Violation, "Você não pode ampliar seus próprios privilégios" if (fingerprint - before).any?
        Audit::RecordService.call(church: @church, user: @actor, module_key: "permissions", action: "Atualizou permissões",
          detail: { profile_id: @profile.id, before: previous, after: @profile.role_permissions.reload.map(&:attributes) }.to_json)
      end
      Success(@profile)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    rescue Access::Integrity::Violation => e
      @profile.errors.add(:base, e.message)
      Failure(@profile.errors)
    end

    private

    def fingerprint
      query = Access::PermissionQuery.new(user: @actor)
      RolePermission::MODULES.keys.product(RolePermission::ACTIONS).flat_map do |mod, action|
        query.scopes(mod, action: action).map { |scope| [ mod, action, scope ] }
      end
    end
  end
end
