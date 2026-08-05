class Event < ApplicationRecord
  include BaseEntity

  belongs_to :departament, optional: true
  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :event_attendees, dependent: :destroy
  has_many :users, through: :event_attendees
  has_one :form, dependent: :destroy

  enum :visibility, { private_event: 0, member_only: 1, public_event: 2 }

  enum :status, {
    draft:            0,
    pending_approval: 1,
    approved:         2,
    rejected:         3,
    cancelled:        4,
    archived:         5
  }

  validates :title, presence: true, length: { minimum: 3 }
  validates :location, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :registration_limit,
            numericality: { greater_than: 0 },
            allow_nil: true,
            if: :registration_enabled?

  validate :end_must_be_after_start
  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  def self.ransackable_attributes(auth_object = nil)
    %w[title location description start_date status visibility departament_id event_attendees_count]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[departament event_attendees]
  end

  def visibility_label
    case visibility
    when "private_event" then "Privada"
    when "member_only" then "Membros"
    when "public_event" then "Pública"
    else visibility&.capitalize
    end
  end

  def editable_by_creator?
    draft? || rejected?
  end

  def status_label
    case status
    when "draft"            then "Rascunho"
    when "pending_approval" then "Aguardando aprovação"
    when "approved"         then "Aprovado"
    when "rejected"         then "Recusado"
    when "cancelled"        then "Cancelado"
    when "archived"         then "Encerrado"
    else status&.capitalize
    end
  end

  # Transições semânticas do fluxo de aprovação (docs/Ekklesia/telas/eventos.md §2, §6).
  def submit_for_approval!(by:)
    unless draft? || rejected?
      raise ArgumentError, "só é possível enviar para aprovação a partir de rascunho ou recusado"
    end

    update!(status: :pending_approval)
  end

  def approve!(by:)
    raise ArgumentError, "só é possível aprovar eventos aguardando aprovação" unless pending_approval?

    update!(status: :approved, approved_by: by, approved_at: Time.current)
  end

  def reject!(by:, reason:)
    raise ArgumentError, "só é possível recusar eventos aguardando aprovação" unless pending_approval?

    update!(status: :rejected, rejection_reason: reason)
  end

  def cancel!(by:, reason:)
    raise ArgumentError, "só é possível cancelar eventos aprovados" unless approved?

    update!(status: :cancelled, cancelled_by: by, cancelled_at: Time.current, cancel_reason: reason)
  end

  private

  def generate_slug
    base = title.parameterize
    candidate = base
    counter = 2
    while Event.where(church_id: church_id).exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def end_must_be_after_start
    return unless start_date.present? && end_date.present?

    if end_date < start_date ||
       (end_date == start_date && end_time.present? && start_time.present? && end_time <= start_time)
      errors.add(:end_date, "deve ser posterior à data e hora de início")
    end
  end
end
