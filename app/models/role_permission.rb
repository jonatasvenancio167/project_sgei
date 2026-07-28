class RolePermission < ApplicationRecord
  MODULES = {
    "calendar"    => "Calendário",
    "events"      => "Eventos",
    "departments" => "Departamentos",
    "schedules"   => "Escalas",
    "members"     => "Membros",
    "birthdays"   => "Aniversariantes",
    "welcome"     => "Acolhimento",
    "forms"       => "Formulários"
  }.freeze

  include BaseEntity

  # Admin ("Secretaria") always has full access, so only these roles are configurable.
  enum :role, { leader: 1, member: 2 }

  validates :module_key, presence: true,
                         inclusion: { in: MODULES.keys },
                         uniqueness: { scope: %i[church_id role] }

  def self.allowed?(church:, role:, module_key:)
    return true if role.to_s == "admin"

    permission = find_by(church: church, role: role, module_key: module_key)
    permission.nil? || permission.allowed?
  end
end
