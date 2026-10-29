module Settings
  class PermissionsController < BaseController
    def update
      profile = policy_scope(AccessProfile).find(params[:profile_id])
      authorize profile, :update?
      permitted = RolePermission::MODULES.keys.index_with { %w[read manage read_scope manage_scope] }
      result = PermissionUpdateService.call(church: current_church, profile: profile,
        permissions: params.fetch(:permissions, ActionController::Parameters.new).permit(permitted), performed_by: current_user)
      case result
      in Success(_)
        redirect_to panel_settings_path(section: "permissions", profile_id: profile.id), notice: t(".success"), status: :see_other
      in Failure(errors)
        redirect_to panel_settings_path(section: "permissions", profile_id: profile.id), alert: errors.full_messages.to_sentence, status: :see_other
      end
    end
  end
end
