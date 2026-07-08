module Settings
  class PermissionsController < BaseController
    # PATCH /settings/permissions
    def update
      result = Settings::PermissionUpdateService.new(
        church: current_church,
        permissions_matrix: permissions_params,
        performed_by: current_user
      ).call

      if result.success?
        redirect_to painel_settings_path(section: "permissions"), notice: "Permissões atualizadas com sucesso."
      else
        redirect_to painel_settings_path(section: "permissions"), alert: result.errors.full_messages.to_sentence
      end
    end

    private

    def permissions_params
      params.fetch(:permissions, ActionController::Parameters.new)
            .permit(RolePermission.roles.keys.index_with { RolePermission::MODULES.keys })
    end
  end
end
