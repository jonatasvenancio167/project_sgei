module Members
  # Self-registration through a Convite de Membro public link
  # (docs/Ekklesia/telas/membros.md §7.6). Creates the member as `pending`
  # and notifies the secretary/pastor for approval.
  class PublicRegistrationService < BaseService
    def initialize(invite:, params:)
      @invite = invite
      @params = params
    end

    def call
      return Failure(:unusable) unless invite.usable?

      user = build_user
      return Failure(user) unless user.save

      invite.use!
      notify_approvers(user)

      Success(user)
    end

    private

    attr_reader :invite, :params

    def build_user
      password = SecureRandom.hex(8)

      invite.church.users.build(
        name: params[:name],
        phone: params[:phone],
        # `email` is unique and required at the DB level; self-registrations
        # without one get a placeholder so the column stays non-null and unique.
        email: params[:email].presence || "sem-email-#{SecureRandom.hex(8)}@ekklesia.local",
        birth_date: params[:birth_date].presence,
        role: :member,
        status: :pending,
        password: password,
        password_confirmation: password
      )
    end

    def notify_approvers(user)
      notification = Notification.create!(
        church: invite.church,
        title: I18n.t("notifications.member_invite_submitted.title"),
        message: I18n.t("notifications.member_invite_submitted.message", name: user.name),
        notification_type: :system
      )

      invite.church.users.where(role: %i[admin pastor]).find_each do |recipient|
        UserNotification.create!(user: recipient, notification: notification, sent_at: Time.current)
      end
    end
  end
end
