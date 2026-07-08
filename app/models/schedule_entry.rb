class ScheduleEntry < ApplicationRecord
  belongs_to :schedule
  has_many :schedule_assignments, dependent: :destroy

  before_validation :derive_month_from_date

  validates :date, presence: true
  validates :month, presence: true, format: { with: /\A\d{4}-\d{2}\z/ }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def derive_month_from_date
    self.month = date.strftime("%Y-%m") if date.present?
  end
end
