class FormSubmissionService
  def initialize(form, submission_params)
    @form   = form
    @params = submission_params
  end

  def call
    response = build_response
    return response unless response.save

    notify_admins(response)
    response
  end

  private

  attr_reader :form, :params

  def build_response
    response = form.form_responses.build(
      token:       SecureRandom.urlsafe_base64(16),
      guest_name:  params[:guest_name],
      guest_email: params[:guest_email],
      guest_phone: params[:guest_phone],
      submitted_at: Time.current
    )

    (params[:answers] || {}).each do |field_id, value|
      field = form.form_fields.find_by(id: field_id)
      next unless field

      stored_value = Array(value).reject(&:blank?).join(", ")
      response.form_answers.build(form: form, form_field: field, value: stored_value)
    end

    response
  end

  def notify_admins(response)
    notification = Notification.create!(
      church:            form.church,
      title:             "Nova inscrição em #{form.title}",
      message:           "#{response.submitter_name} (#{response.submitter_email}) preencheu o formulário.",
      notification_type: :form_submission
    )

    recipients = form.church.users.where(role: :admin)
    recipients += form.departament.users if form.departament.present?

    recipients.uniq.each do |user|
      UserNotification.create!(user: user, notification: notification, sent_at: Time.current)
    end
  end
end
