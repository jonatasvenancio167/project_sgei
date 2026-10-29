class RolePermission < ApplicationRecord
  MODULES = {
    "calendar" => "Calendário", "events" => "Eventos", "departments" => "Ministérios",
    "schedules" => "Escalas", "members" => "Membros", "birthdays" => "Aniversariantes",
    "welcome" => "Acolhimento", "forms" => "Formulários", "settings" => "Configurações",
    "access" => "Gestão de acessos"
  }.freeze
  ACTIONS = %w[read manage].freeze
  SCOPES = %w[own team led church hierarchy audience].freeze
  include BaseEntity
  belongs_to :access_profile, optional: true # nullable only for retained legacy rows
  enum :role, { leader: 1, member: 2 }
  validates :module_key, inclusion: { in: MODULES.keys }
  validates :action_key, inclusion: { in: ACTIONS }
  validates :scope_key, inclusion: { in: SCOPES }
  validates :module_key, uniqueness: { scope: [ :access_profile_id, :action_key ] }, if: :access_profile_id?
  validate do
    errors.add(:access_profile, :invalid) if access_profile && access_profile.church_id != church_id
  end
end
