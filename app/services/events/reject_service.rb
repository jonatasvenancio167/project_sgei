module Events
  class RejectService < BaseService
    def initialize(event:, performed_by:, reason:)
      @event = event
      @performed_by = performed_by
      @reason = reason
    end

    def call
      if reason.blank?
        event.errors.add(:rejection_reason, "não pode ficar em branco")
        return Failure(event)
      end

      event.reject!(by: performed_by, reason: reason)
      Audit::RecordService.call(
        church: event.church, user: performed_by,
        module_key: "events", action: "Recusou evento", detail: "#{event.title} — #{reason}"
      )
      Events::NotifyService.call(event: event, kind: :rejected)
      Success(event)
    rescue ArgumentError => e
      event.errors.add(:base, e.message)
      Failure(event)
    end

    private

    attr_reader :event, :performed_by, :reason
  end
end
