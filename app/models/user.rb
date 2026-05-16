class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :church
  has_many :memberchips, dependent: :destroy
  has_many :departaments, through: :memberchips
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees

  enum :status, { active: 0, inactive: 1 }, prefix: true
  enum :role, { admin: 0, leader: 1, member: 2 }

  def role_label
    case role
    when "admin" then "Secretaria"
    when "leader" then "Líder de Departamento"
    when "member" then "Membro"
    else role&.capitalize
    end
  end

  def primary_department
    departaments.first
  end

  def primary_department_name
    primary_department&.name || "Geral"
  end

  def can_see_dept?(dept)
    return true if admin?
    return true if dept.blank? || dept == "Geral"
    
    departaments.pluck(:name).include?(dept)
  end
end
