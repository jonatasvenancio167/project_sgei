class MemberInvite < ApplicationRecord
  include BaseEntity

  belongs_to :created_by, class_name: "User"

  enum :status, { active: 0, expired: 1, exhausted: 2, deactivated: 3 }

  # Selectable expiration windows for the "Convite de Membro" modal
  # (docs/Ekklesia/telas/membros.md §7.3).
  EXPIRES_IN_OPTIONS = {
    "24h"     => 1.day,
    "3_days"  => 3.days,
    "7_days"  => 7.days,
    "15_days" => 15.days,
    "30_days" => 30.days
  }.freeze

  validates :max_uses, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 500 }
  validates :expires_at, presence: true

  before_create :generate_token

  scope :usable, -> { active.where("expires_at > ?", Time.current).where("uses_count < max_uses") }

  def usable?
    active? && expires_at > Time.current && uses_count < max_uses
  end

  def use!
    increment!(:uses_count)
    update!(status: :exhausted) if uses_count >= max_uses
  end

  def deactivate!
    update!(status: :deactivated)
  end

  def remaining_uses
    max_uses - uses_count
  end

  def expired?
    expires_at <= Time.current
  end

  private

  def generate_token
    self.token = loop do
      candidate = SecureRandom.urlsafe_base64(16)
      break candidate unless MemberInvite.exists?(token: candidate)
    end
  end
end
