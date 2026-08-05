module Events
  # Creates an event and assigns its initial status per the approval rule in
  # docs/Ekklesia/telas/eventos.md §3.2: the secretary (admin) publishes
  # directly; Pastor, Copastor and Líder de departamento send it to the
  # secretary for approval.
  class CreateService < BaseService
    def initialize(church:, creator:, params:)
      @church = church
      @creator = creator
      @params = params
    end

    def call
      event = church.events.build(params)
      event.creator = creator
      assign_initial_status(event)

      return Failure(event) unless event.save

      audit(event)
      Events::NotifyService.call(event: event, kind: :submitted) if event.pending_approval?
      Success(event)
    end

    private

    attr_reader :church, :creator, :params

    def audit(event)
      Audit::RecordService.call(
        church: church, user: creator,
        module_key: "events", action: "Criou evento", detail: "#{event.title} (#{event.status_label})"
      )
    end

    def assign_initial_status(event)
      if creator.admin?
        event.status = :approved
        event.approved_by = creator
        event.approved_at = Time.current
      else
        event.status = :pending_approval
      end
    end
  end
end
