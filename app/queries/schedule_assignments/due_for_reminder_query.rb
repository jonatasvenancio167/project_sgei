module ScheduleAssignments
  # Assignments for a given date that haven't received the reminder due
  # `days` in advance yet, preloaded for ScheduleReminderJob.
  class DueForReminderQuery
    def initialize(date:, days:)
      @date = date
      @days = days
    end

    def call
      ScheduleAssignment
        .joins(:schedule_entry)
        .where(schedule_entries: { date: date })
        .where(ScheduleAssignment::REMINDERS.fetch(days) => nil)
        .includes(:user, :schedule_column, schedule_entry: { schedule: :church })
    end

    private

    attr_reader :date, :days
  end
end
