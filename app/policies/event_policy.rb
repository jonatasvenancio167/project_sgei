# frozen_string_literal: true

class EventPolicy < ChurchModulePolicy
  MODULE_KEY = "events"

  # Secretaria, Administrador (Pastor/Copastor) e Líder de departamento podem
  # criar eventos (docs/Ekklesia/telas/eventos.md §3.1) — só a Secretaria
  # publica direto, os demais entram em aprovação (Events::CreateService).
  def create?
    admin? || leader? || pastor? || co_pastor?
  end

  # Secretaria edita qualquer evento da própria church; os demais perfis que
  # podem criar evento só editam os próprios enquanto rascunho/recusado (§3.3).
  def update?
    return false unless same_church?

    admin? || (creator? && record.editable_by_creator?)
  end

  # Sem exclusão física — ver #cancel? (§9.1: cancelar nunca apaga o registro).
  def destroy? = false

  def approve?  = admin? && same_church? && record.pending_approval?
  def reject?   = admin? && same_church? && record.pending_approval?
  def cancel?   = admin? && same_church? && record.approved?
  def resubmit? = same_church? && creator? && record.rejected?

  private

  def creator?
    record.created_by_id.present? && record.created_by_id == user.id
  end
end
