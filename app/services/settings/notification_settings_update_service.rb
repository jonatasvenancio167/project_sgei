module Settings
  class NotificationSettingsUpdateService < BaseService
    # settings_matrix: { "event_created" => { "active" => "1", "channel" => "email" }, ... }
    def initialize(church:, settings_matrix:, performed_by:)
      @church = church
      @settings_matrix = settings_matrix.to_h
      @performed_by = performed_by
    end

    def call
      ActiveRecord::Base.transaction do
        NotificationSetting::EVENTS.each_key do |event_key|
          values = settings_matrix.fetch(event_key, {})
          setting = church.notification_settings.find_or_initialize_by(event_key: event_key)
          setting.update!(
            active: ActiveModel::Type::Boolean.new.cast(values["active"]) || false,
            channel: NotificationSetting.channels.key?(values["channel"]) ? values["channel"] : setting.channel
          )
        end
      end

      Audit::RecordService.call(
        church: church, user: performed_by,
        module_key: "notifications", action: "Atualizou preferências de notificação"
      )
      Success(true)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end

    private

    attr_reader :church, :settings_matrix, :performed_by
  end
end
