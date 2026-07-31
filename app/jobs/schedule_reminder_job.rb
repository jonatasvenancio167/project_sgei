class ScheduleReminderJob < ApplicationJob
  queue_as :default

  def perform
    ScheduleAssignment::REMINDERS.each do |days, column|
      target_date = Date.current + days

      ScheduleAssignments::DueForReminderQuery.new(date: target_date, days: days).call
        .find_each { |assignment| send_reminder(assignment, days, column) }
    end
  end

  private

  def send_reminder(assignment, days, column)
    schedule = assignment.schedule_entry.schedule
    day = assignment.schedule_entry.date.strftime("%d/%m")
    when_label = days == 1 ? I18n.t("notifications.schedule_reminder.tomorrow") : I18n.t("notifications.schedule_reminder.in_days", days: days)

    ActiveRecord::Base.transaction do
      notification = Notification.create!(
        church: schedule.church,
        title: I18n.t("notifications.schedule_reminder.title"),
        message: I18n.t("notifications.schedule_reminder.message",
                        when: when_label, day: day, schedule: schedule.name, column: assignment.schedule_column.name),
        notification_type: :schedule
      )
      UserNotification.create!(user: assignment.user, notification: notification, sent_at: Time.current)
      assignment.update_column(column, Time.current)
    end
  end
end
