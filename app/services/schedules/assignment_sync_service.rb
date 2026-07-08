module Schedules
  # Extracts the members linked in "member"-type columns of an entry,
  # keeps schedule_assignments in sync and notifies newly assigned members.
  class AssignmentSyncService
    def initialize(entry:)
      @entry = entry
      @schedule = entry.schedule
    end

    def call
      desired = extract_assignments
      current = entry.schedule_assignments.to_a

      created = []
      ActiveRecord::Base.transaction do
        current.each do |assignment|
          key = [assignment.user_id, assignment.schedule_column_id]
          assignment.destroy unless desired.any? { |d| [d[:user_id], d[:schedule_column_id]] == key }
        end

        desired.each do |attrs|
          next if current.any? { |a| a.user_id == attrs[:user_id] && a.schedule_column_id == attrs[:schedule_column_id] }

          created << entry.schedule_assignments.create!(attrs)
        end
      end

      created.each { |assignment| notify(assignment) }
      created
    end

    private

    attr_reader :entry, :schedule

    def extract_assignments
      schedule.schedule_columns.select { |c| c.column_type == "member" }.filter_map do |column|
        user_id = entry.cell_values[column.id.to_s].presence&.to_i
        next if user_id.blank? || user_id.zero?
        next unless User.exists?(id: user_id, church_id: schedule.church_id)

        { user_id: user_id, schedule_column_id: column.id }
      end
    end

    def notify(assignment)
      notification = Notification.create!(
        church: schedule.church,
        title: "Você foi escalado",
        message: "Você foi escalado em #{schedule.name} no dia #{entry.date.strftime('%d/%m/%Y')} como #{assignment.schedule_column.name}.",
        notification_type: :schedule
      )
      UserNotification.create!(user: assignment.user, notification: notification, sent_at: Time.current)
    end
  end
end
