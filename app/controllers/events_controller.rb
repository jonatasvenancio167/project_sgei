class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update ]

  # GET /events or /events.json
  def index
    authorize Event
    @user = current_user
    q, events = EventQuery.new(params, user: @user).call
    per = [params[:per].to_i, 10].max
    per = Shared::PaginationComponent::PAGE_SIZE_OPTIONS.include?(per) ? per : 10
    @pagy, @events = pagy(events, limit: per)
    @decorator = ::Events::IndexDecorator.new(q, @events, params, @user, view_context, total_count: @pagy.count)
    @event = Event.new # For the modal form
  end




  # GET /events/1 or /events/1.json
  def show
    @decorator = EventDecorator.new(@event, view_context)
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    authorize Event

    result = Events::CreateService.call(church: current_user.church, creator: current_user, params: event_params)

    respond_to do |format|
      case result
      in Success(event)
        @event = event
        format.html { redirect_to panel_events_path, notice: t(".success") }
        format.turbo_stream
      in Failure(event)
        @event = event
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_event_form", partial: "events/form", locals: { event: @event }) }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        audit_update
        format.html { redirect_to panel_events_path, notice: t(".success"), status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = policy_scope(Event).find(params[:id])
      authorize @event
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:title, :slug, :description, :thumbnail, :location,
                                     :start_date, :start_time, :end_date, :end_time,
                                     :departament_id, :visibility,
                                     :registration_enabled, :registration_limit)
    end

    # §9.2: toda edição fica registrada com um snapshot antes/depois.
    def audit_update
      changes = @event.saved_changes.except("updated_at").map { |field, (before, after)| "#{field}: #{before.inspect} → #{after.inspect}" }.join(", ")
      Audit::RecordService.call(
        church: @event.church, user: current_user,
        module_key: "events", action: "Editou evento", detail: changes.presence || @event.title
      )
    end
end
