module Events
  # Reenvio após recusa (docs/Ekklesia/telas/eventos.md §6.4): o criador edita
  # e reenvia; o histórico de recusas anteriores fica no AuditLog.
  class ResubmitService < BaseService
    def initialize(event:, performed_by:)
      @event = event
      @performed_by = performed_by
    end

    def call
      event.submit_for_approval!(by: performed_by)
      Audit::RecordService.call(
        church: event.church, user: performed_by,
        module_key: "events", action: "Reenviou evento para aprovação", detail: event.title
      )
      Events::NotifyService.call(event: event, kind: :submitted)
      Success(event)
    rescue ArgumentError => e
      event.errors.add(:base, e.message)
      Failure(event)
    end

    private

    attr_reader :event, :performed_by
  end
end
