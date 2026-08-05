module Events
  # POST /events/:event_id/approval
  class ApprovalsController < ApplicationController
    def create
      event = policy_scope(Event).find(params[:event_id])
      authorize event, :approve?

      result = Events::ApproveService.call(event: event, performed_by: current_user)

      case result
      in Success(event)
        redirect_to panel_events_path, notice: t(".success", title: event.title)
      in Failure(event)
        redirect_to panel_events_path, alert: event.errors.full_messages.to_sentence
      end
    end
  end
end
