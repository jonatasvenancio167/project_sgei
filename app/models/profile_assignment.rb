class ProfileAssignment < ApplicationRecord
  include BaseEntity
  belongs_to :church_membership
  belongs_to :access_profile
  around_destroy { |assignment, block| Access::Integrity.guard(assignment.church, &block) }
  validates :access_profile_id, uniqueness: { scope: :church_membership_id }
  validate :same_tenant

  private

  def same_tenant
    unless church_membership&.church_id == church_id && access_profile&.church_id == church_id
      errors.add(:base, "Perfil e vínculo devem pertencer à mesma igreja")
    end
  end
end
