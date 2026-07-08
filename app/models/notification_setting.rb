class NotificationSetting < ApplicationRecord
  EVENTS = {
    "event_created"     => "Novo evento criado",
    "schedule_assigned" => "Escala publicada ou atualizada",
    "schedule_reminder" => "Lembrete de escala (7, 3 e 1 dia antes)",
    "form_response"     => "Nova resposta de formulário",
    "member_birthday"   => "Aniversário de membro"
  }.freeze

  belongs_to :church

  enum :channel, { email: 0, whatsapp: 1, both: 2 }, prefix: true

  validates :event_key, presence: true,
                        inclusion: { in: EVENTS.keys },
                        uniqueness: { scope: :church_id }

  def label
    EVENTS[event_key]
  end
end
