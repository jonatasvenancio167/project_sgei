class ScheduleAssignment < ApplicationRecord
  REMINDERS = { 7 => :reminder_7d_sent_at, 3 => :reminder_3d_sent_at, 1 => :reminder_1d_sent_at }.freeze

  belongs_to :schedule_entry
  belongs_to :user
  belongs_to :schedule_column

  has_one :schedule, through: :schedule_entry

  validates :user_id, uniqueness: { scope: [:schedule_entry_id, :schedule_column_id] }
end
