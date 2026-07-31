module Settings
  class PermissionUpdateService < BaseService
    # permissions_matrix: { "leader" => { "events" => "1", ... }, "member" => { ... } }
    def initialize(church:, permissions_matrix:, performed_by:)
      @church = church
      @permissions_matrix = permissions_matrix.to_h
      @performed_by = performed_by
    end

    def call
      ActiveRecord::Base.transaction do
        RolePermission.roles.each_key do |role|
          role_values = permissions_matrix.fetch(role, {})

          RolePermission::MODULES.each_key do |module_key|
            permission = church.role_permissions.find_or_initialize_by(role: role, module_key: module_key)
            permission.update!(allowed: ActiveModel::Type::Boolean.new.cast(role_values[module_key]) || false)
          end
        end
      end

      Audit::RecordService.call(
        church: church, user: performed_by,
        module_key: "permissions", action: "Atualizou permissões por módulo"
      )
      Success(true)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end

    private

    attr_reader :church, :permissions_matrix, :performed_by
  end
end
