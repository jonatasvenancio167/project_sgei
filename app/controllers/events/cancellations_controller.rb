module Events
  # POST /events/:event_id/cancellation
  class CancellationsController < ApplicationController
    def create
      event = policy_scope(Event).find(params[:event_id])
      authorize event, :cancel?

      result = Events::CancelService.call(event: event, performed_by: current_user, reason: params[:reason])

      case result
      in Success(event)
        redirect_to panel_events_path, notice: t(".success", title: event.title)
      in Failure(event)
        redirect_to panel_events_path, alert: event.errors.full_messages.to_sentence
      end
    end
  end
end
