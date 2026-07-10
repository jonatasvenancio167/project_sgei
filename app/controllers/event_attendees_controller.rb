class EventAttendeesController < ApplicationController
  before_action :set_event_attendee, only: %i[ show edit update destroy ]

  # GET /event_attendees or /event_attendees.json
  def index
    authorize EventAttendee
    @event_attendees = policy_scope(EventAttendee)
  end

  # GET /event_attendees/1 or /event_attendees/1.json
  def show
  end

  # GET /event_attendees/new
  def new
    @event_attendee = EventAttendee.new
    authorize @event_attendee
  end

  # GET /event_attendees/1/edit
  def edit
  end

  # POST /event_attendees or /event_attendees.json
  def create
    @event_attendee = EventAttendee.new(event_attendee_params)
    authorize @event_attendee

    respond_to do |format|
      if @event_attendee.save
        format.html { redirect_to @event_attendee, notice: "Event attendee was successfully created." }
        format.json { render :show, status: :created, location: @event_attendee }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_attendees/1 or /event_attendees/1.json
  def update
    respond_to do |format|
      if @event_attendee.update(event_attendee_params)
        format.html { redirect_to @event_attendee, notice: "Event attendee was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @event_attendee }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_attendees/1 or /event_attendees/1.json
  def destroy
    @event_attendee.destroy!

    respond_to do |format|
      format.html { redirect_to event_attendees_path, notice: "Event attendee was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_attendee
      @event_attendee = policy_scope(EventAttendee).find(params.expect(:id))
      authorize @event_attendee
    end

    # Only allow a list of trusted parameters through.
    def event_attendee_params
      params.fetch(:event_attendee, {})
    end
end
