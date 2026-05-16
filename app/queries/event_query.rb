class EventQuery
  def initialize(params = {}, user:)
    @params = params
    @user = user
  end

  def call
    # Default sorting by start_date if not specified
    @params[:q] ||= {}
    @params[:q][:s] ||= "start_date asc"

    @q = Event.includes(:departament, :event_attendees).ransack(@params[:q])
    @events = @q.result(distinct: true)

    apply_permission_filter
    apply_period_filter
    apply_sorting

    [@q, @events]
  end

  private

  def apply_permission_filter
    unless @user.admin?
      @events = @events.where(departament_id: @user.departament_ids + [nil])
    end
  end

  def apply_period_filter
    case @params[:period]
    when "hoje"
      @events = @events.where(start_date: Date.current.all_day)
    when "semana"
      @events = @events.where(start_date: Date.current..7.days.from_now.end_of_day)
    when "mes"
      @events = @events.where(start_date: Date.current..30.days.from_now.end_of_day)
    end
  end

  def apply_sorting
    # Special handling for "inscritos" if needed, but Ransack might handle it if we add an attribute
    if @params[:q][:s]&.include?("inscritos")
      # This is tricky with Ransack on a result set, usually handled via ransackable_scopes or similar
      # For now, we'll let Ransack handle standard fields.
    end
  end
end
