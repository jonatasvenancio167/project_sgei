class Memberchip < ApplicationRecord
  validate do
    if user && departament && !user.church_memberships.exists?(church_id: departament.church_id)
      errors.add(:user, "deve pertencer à igreja do ministério")
    end
  end
  belongs_to :user
  belongs_to :departament

  enum :role, { member: 0, leader: 1 }

  validates :user_id, uniqueness: { scope: :departament_id }
end
