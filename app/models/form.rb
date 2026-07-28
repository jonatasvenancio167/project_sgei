class Form < ApplicationRecord
  include BaseEntity

  belongs_to :event, optional: true
  belongs_to :departament, optional: true
  has_many :form_fields, dependent: :destroy
  has_many :form_responses, dependent: :destroy

  validates :title, presence: true
  validates :slug, uniqueness: true, allow_nil: true

  before_validation :generate_slug, on: :create

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :active,      -> { not_deleted.where(active: true) }

  def status_label
    active? ? "Aberto" : "Encerrado"
  end

  def responses_count
    form_responses.count
  end

  def fill_percentage
    return 0 unless limit&.positive?
    [(responses_count * 100.0 / limit).round, 100].min
  end

  private

  def generate_slug
    return if slug.present?
    base      = title.to_s.parameterize
    candidate = base
    n         = 2
    while Form.exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end
end
