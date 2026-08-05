module Events
  class ApproveService < BaseService
    def initialize(event:, performed_by:)
      @event = event
      @performed_by = performed_by
    end

    def call
      event.approve!(by: performed_by)
      Audit::RecordService.call(
        church: event.church, user: performed_by,
        module_key: "events", action: "Aprovou evento", detail: event.title
      )
      Events::NotifyService.call(event: event, kind: :approved)
      Success(event)
    rescue ArgumentError => e
      event.errors.add(:base, e.message)
      Failure(event)
    end

    private

    attr_reader :event, :performed_by
  end
end
