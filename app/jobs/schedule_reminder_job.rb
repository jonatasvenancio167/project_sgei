class ScheduleReminderJob < ApplicationJob
  queue_as :default

  def perform
    ScheduleAssignment::REMINDERS.each do |days, column|
      target_date = Date.current + days

      ScheduleAssignment
        .on_date(target_date)
        .without_reminder(days)
        .includes(:user, :schedule_column, schedule_entry: { schedule: :church })
        .find_each { |assignment| send_reminder(assignment, days, column) }
    end
  end

  private

  def send_reminder(assignment, days, column)
    schedule = assignment.schedule_entry.schedule
    day = assignment.schedule_entry.date.strftime("%d/%m")
    when_label = days == 1 ? "amanhã" : "em #{days} dias"

    ActiveRecord::Base.transaction do
      notification = Notification.create!(
        church: schedule.church,
        title: "Lembrete de escala",
        message: "Você está escalado #{when_label} (#{day}) em #{schedule.name} como #{assignment.schedule_column.name}.",
        notification_type: :schedule
      )
      UserNotification.create!(user: assignment.user, notification: notification, sent_at: Time.current)
      assignment.update_column(column, Time.current)
    end
  end
end
