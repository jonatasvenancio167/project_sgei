# A person welcomed at a service (visitante ou irmão de outra congregação),
# registered by the reception team.
class WelcomeRecord < ApplicationRecord
  SERVICES = [
    "Culto de Domingo (manhã)",
    "Culto de Domingo (noite)",
    "Culto de Oração",
    "Culto de Ensino",
    "Vigília",
    "Evento especial"
  ].freeze

  belongs_to :church
  belongs_to :registered_by, class_name: "User", optional: true

  enum :visitor_type, { visitor: 0, brother: 1 }, prefix: true

  validates :name, presence: { message: "é obrigatório" }
  validates :service, presence: { message: "é obrigatório" },
                      inclusion: { in: SERVICES, message: "inválido" }

  scope :registered_on, ->(date) { where(created_at: date.all_day) }

  def visitor_type_label
    visitor_type_visitor? ? "Visitante" : "Irmão"
  end
end
