class ChurchMembership < ApplicationRecord
  include BaseEntity
  belongs_to :user
  has_many :profile_assignments, dependent: :destroy
  has_many :access_profiles, through: :profile_assignments
  around_update { |membership, block| Access::Integrity.guard(membership.church, &block) }
  around_destroy { |membership, block| Access::Integrity.guard(membership.church, &block) }
  validate do
    errors.add(:access_enabled, "exige credenciais de acesso") if access_enabled? && user&.encrypted_password.blank?
  end
  validates :user_id, uniqueness: { scope: :church_id }
end
