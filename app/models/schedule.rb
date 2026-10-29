class Schedule < ApplicationRecord
  validate do
    errors.add(:departament, "deve pertencer à mesma igreja") if departament && departament.church_id != church_id
  end
  COLOR_CHOICES = Departament::COLOR_CHOICES

  include BaseEntity

  belongs_to :departament
  has_many :schedule_columns, -> { order(:position) }, dependent: :destroy, inverse_of: :schedule
  has_many :schedule_entries, dependent: :destroy

  validates :name, presence: true
  validates :color, presence: true, inclusion: { in: COLOR_CHOICES.map { |c| c[:key] } }
  validates :departament, presence: true

  accepts_nested_attributes_for :schedule_columns, allow_destroy: true
end
