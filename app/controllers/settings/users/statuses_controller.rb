module Settings
  module Users
    class StatusesController < Settings::BaseController
      # PATCH /settings/users/:user_id/status
      def update
        result = Settings::UserToggleStatusService.call(
          user: User.where(id: current_church.church_memberships.select(:user_id)).find(params[:user_id]),
          performed_by: current_user
        )

        case result
        in Success(user)
          notice = user.church_memberships.find_by!(church: current_church).active? ? t(".activated", name: user.name) : t(".deactivated", name: user.name)
          redirect_to users_section_path, notice: notice
        in Failure(user)
          redirect_to users_section_path, alert: user.errors.full_messages.to_sentence
        end
      end

      private

      def users_section_path
        panel_settings_path(params.permit(:q, :role, :status).to_h.merge(section: "users"))
      end
    end
  end
end
