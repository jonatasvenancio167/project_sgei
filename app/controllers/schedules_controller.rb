class SchedulesController < ApplicationController
  before_action :set_schedule, only: %i[show update destroy]

  def index
    load_index_data
    @schedule = Schedule.new
  end

  def show
    @month = params[:month]
    @decorator = ScheduleDecorator.new(@schedule, view_context)
    @columns = @schedule.schedule_columns.order(:position)
    @entries = @schedule.schedule_entries.where(month: @month).order(:date, :position)
    remap_orphaned_entries(@entries, @columns)

    dept_members = @schedule.departament.users.where(deleted_at: nil).order(:name)
    if dept_members.any?
      @dept_members         = dept_members
      @members_source_label = @schedule.departament.name
    else
      @dept_members         = current_user.church.users.where(deleted_at: nil).order(:name)
      @members_source_label = nil
    end

    member_col_ids = @columns.select { |c| c.column_type == "member" }.map { |c| c.id.to_s }

    @member_counts = Hash.new(0)
    @entries.each do |entry|
      member_col_ids.each { |cid| @member_counts[entry.cell_values[cid]] += 1 if entry.cell_values[cid].present? }
    end
    @users_map = member_col_ids.any? ? User.where(id: @member_counts.keys).index_by { |u| u.id.to_s } : {}
    scheduled = @member_counts.keys
    @scheduled_members   = @dept_members.select { |m| scheduled.include?(m.id.to_s) }
    @unscheduled_members = @dept_members.reject { |m| scheduled.include?(m.id.to_s) }
  end

  def create
    result = Schedules::CreateService.new(
      church: current_user.church,
      params: schedule_params,
      columns: columns_params
    ).call

    if result.success?
      redirect_to painel_schedule_month_path(result.schedule, month: current_month), notice: "Escala criada com sucesso."
    else
      load_index_data
      @schedule = result.schedule
      flash.now[:alert] = result.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def update
    result = Schedules::UpdateService.new(
      schedule: @schedule,
      params: schedule_params,
      columns: columns_params
    ).call

    if result.success?
      redirect_to painel_schedules_path, notice: "Escala atualizada com sucesso."
    else
      redirect_to painel_schedules_path, alert: result.errors.full_messages.to_sentence
    end
  end

  def destroy
    @schedule.destroy
    redirect_to painel_schedules_path, notice: "Escala excluída com sucesso."
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

  def remap_orphaned_entries(entries, columns)
    col_ids = columns.map { |c| c.id.to_s }
    return if col_ids.empty?

    entries.each do |entry|
      next if entry.cell_values.blank?
      next if (entry.cell_values.keys & col_ids).any?

      sorted_values = entry.cell_values.sort_by { |k, _| k.to_i }.map { |_, v| v }
      new_values = col_ids.each_with_index.with_object({}) { |(id, i), h| h[id] = sorted_values[i] }
      entry.update_columns(cell_values: new_values)
    end
  end
end
