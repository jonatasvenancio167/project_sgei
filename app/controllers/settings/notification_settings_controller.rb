module Settings
  class NotificationSettingsController < BaseController
    # PATCH /settings/notification_settings
    def update
      result = Settings::NotificationSettingsUpdateService.call(
        church: current_church,
        settings_matrix: notification_settings_params,
        performed_by: current_user
      )

      case result
      in Success(_)
        redirect_to panel_settings_path(section: "notifications"), notice: t(".success")
      in Failure(errors)
        redirect_to panel_settings_path(section: "notifications"), alert: errors.full_messages.to_sentence
      end
    end

    private

    def notification_settings_params
      params.fetch(:notification_settings, ActionController::Parameters.new)
            .permit(NotificationSetting::EVENTS.keys.index_with { %i[active channel] })
    end
  end
end
