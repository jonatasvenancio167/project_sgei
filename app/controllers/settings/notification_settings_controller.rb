module Settings
  class NotificationSettingsController < BaseController
    # PATCH /settings/notification_settings
    def update
      result = Settings::NotificationSettingsUpdateService.new(
        church: current_church,
        settings_matrix: notification_settings_params,
        performed_by: current_user
      ).call

      if result.success?
        redirect_to painel_settings_path(section: "notifications"), notice: "Notificações atualizadas com sucesso."
      else
        redirect_to painel_settings_path(section: "notifications"), alert: result.errors.full_messages.to_sentence
      end
    end

    private

    def notification_settings_params
      params.fetch(:notification_settings, ActionController::Parameters.new)
            .permit(NotificationSetting::EVENTS.keys.index_with { %i[active channel] })
    end
  end
end
