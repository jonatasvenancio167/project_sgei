class EventsController < ApplicationController
  before_action :set_event, only: %i[ show edit update destroy ]

  # GET /events or /events.json
  def index
    @user = current_user
    q, events = EventQuery.new(params, user: @user).call
    @pagy, @events = pagy(events)
    @decorator = ::Events::IndexDecorator.new(q, @events, params, @user, view_context)
    @event = Event.new # For the modal form
  end




  # GET /events/1 or /events/1.json
  def show
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
    @event = Event.new(event_params)
    @event.church = current_user.church
    @event.creator = current_user

    respond_to do |format|
      if @event.save
        format.html { redirect_to painel_eventos_path, notice: "Evento criado com sucesso." }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_event_form", partial: "events/form", locals: { event: @event }) }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to painel_eventos_path, notice: "Evento atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to painel_eventos_path, notice: "Evento removido com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:title, :slug, :description, :thumbnail, :location, :start_date, :end_date, :departament_id, :visibility)
    end
end
