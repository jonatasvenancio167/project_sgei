module Settings
  module Congregations
    class StatusesController < Settings::BaseController
      # PATCH /settings/congregations/:congregation_id/status
      def update
        result = Settings::CongregationToggleStatusService.call(
          congregation: current_church.congregations.find(params[:congregation_id]),
          performed_by: current_user
        )

        case result
        in Success(congregation)
          notice = congregation.status_active? ? t(".activated") : t(".deactivated")
          redirect_to panel_settings_path(section: "congregations"), notice: notice
        in Failure(congregation)
          redirect_to panel_settings_path(section: "congregations"), alert: congregation.errors.full_messages.to_sentence
        end
      end
    end
  end
end
