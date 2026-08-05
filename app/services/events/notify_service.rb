module Events
  # In-app notifications for the approval workflow (docs/Ekklesia/telas/eventos.md §6.2).
  class NotifyService < BaseService
    KINDS = %i[submitted approved rejected cancelled].freeze

    def initialize(event:, kind:)
      raise ArgumentError, "kind inválido: #{kind}" unless KINDS.include?(kind)

      @event = event
      @kind = kind
    end

    def call
      recipients.each { |user| notify(user) }
      Success(event)
    end

    private

    attr_reader :event, :kind

    def recipients
      case kind
      when :submitted then event.church.users.where(role: :admin)
      when :approved, :rejected then Array(event.creator)
      when :cancelled then event.users
      end
    end

    def notify(user)
      notification = Notification.create!(
        church: event.church,
        title: I18n.t("notifications.event_#{kind}.title"),
        message: I18n.t("notifications.event_#{kind}.message", **message_options),
        notification_type: :event
      )
      UserNotification.create!(user: user, notification: notification, sent_at: Time.current)
    end

    def message_options
      { title: event.title, reason: event.rejection_reason || event.cancel_reason }
    end
  end
end
