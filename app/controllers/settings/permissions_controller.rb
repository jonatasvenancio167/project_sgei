module Settings
  class PermissionsController < BaseController
    # PATCH /settings/permissions
    def update
      result = Settings::PermissionUpdateService.call(
        church: current_church,
        permissions_matrix: permissions_params,
        performed_by: current_user
      )

      case result
      in Success(_)
        redirect_to panel_settings_path(section: "permissions"), notice: t(".success")
      in Failure(errors)
        redirect_to panel_settings_path(section: "permissions"), alert: errors.full_messages.to_sentence
      end
    end

    private

    def permissions_params
      params.fetch(:permissions, ActionController::Parameters.new)
            .permit(RolePermission.roles.keys.index_with { RolePermission::MODULES.keys })
    end
  end
end
