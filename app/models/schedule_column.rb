class ScheduleColumn < ApplicationRecord
  COLUMN_TYPES = {
    "text"    => "Texto",
    "member"  => "Membro",
    "date"    => "Data",
    "time"    => "Hora",
    "number"  => "Número",
    "boolean" => "Sim/Não"
  }.freeze

  belongs_to :schedule, inverse_of: :schedule_columns

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :column_type, inclusion: { in: COLUMN_TYPES.keys }
end
