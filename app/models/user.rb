class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :status, { active: 0, inactive: 1 }, prefix: true
  enum :role, { admin: 0, leader: 1, member: 2 }
end
