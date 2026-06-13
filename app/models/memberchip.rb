class Memberchip < ApplicationRecord
  belongs_to :user
  belongs_to :departament

  enum :role, { member: 0, leader: 1 }

  validates :user_id, uniqueness: { scope: :departament_id, message: "já é membro deste departamento" }
end
