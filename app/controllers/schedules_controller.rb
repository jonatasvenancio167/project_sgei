class SchedulesController < ApplicationController
  before_action :set_schedule, only: %i[show update destroy]

  def index
    authorize Schedule
    load_index_data
    @schedule = Schedule.new
  end

  def show
    @presenter = Schedules::ShowPresenter.new(
      schedule: @schedule, month: params[:month], view_context: view_context, church: current_user.church
    )

    respond_to do |format|
      format.html
      format.pdf do
        pdf = SchedulePdf.new(schedule: @schedule, month: @presenter.month, columns: @presenter.columns,
                              entries: @presenter.entries, users_map: @presenter.users_map)
        send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "attachment"
      end
    end
  end

  def create
    authorize Schedule, :create?
    result = Schedules::CreateService.call(
      church: current_user.church,
      params: schedule_params,
      columns: columns_params
    )

    case result
    in Success(schedule)
      redirect_to panel_schedule_month_path(schedule, month: current_month), notice: t(".success")
    in Failure(schedule)
      load_index_data
      @schedule = schedule
      flash.now[:alert] = schedule.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def update
    result = Schedules::UpdateService.call(
      schedule: @schedule,
      params: schedule_params,
      columns: columns_params
    )

    case result
    in Success(schedule)
      redirect_to panel_schedules_path, notice: t(".success")
    in Failure(schedule)
      redirect_to panel_schedules_path, alert: schedule.errors.full_messages.to_sentence
    end
  end

  def destroy
    @schedule.destroy
    redirect_to panel_schedules_path, notice: t(".success")
  end

  private

  def load_index_data
    @user = current_user
    schedules = ScheduleQuery.new(user: @user).call
    @decorator = Schedules::IndexDecorator.new(schedules, @user, view_context)
  end

  def set_schedule
    scope = current_user.church.schedules
    scope = scope.where(departament_id: current_user.departament_ids) unless current_user.admin?
    @schedule = scope.find(params[:id])
    authorize @schedule
  end

  def schedule_params
    params.require(:schedule).permit(:name, :departament_id, :color)
  end

  def columns_params
    return [] unless params[:columns]
    params[:columns].map { |c| c.permit(:name, :type) }
  end

  def current_month
    Date.current.strftime("%Y-%m")
  end
end
