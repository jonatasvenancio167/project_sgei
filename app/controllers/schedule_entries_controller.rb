class ScheduleEntriesController < ApplicationController
  before_action :set_schedule

  def create
    month = params[:month]
    date = params.dig(:entry, :date)
    cell_values = params.dig(:entry, :cell_values)&.permit!&.to_h || {}
    position = @schedule.schedule_entries.where(month: month).count

    entry = @schedule.schedule_entries.create!(month: month, date: date, position: position, cell_values: cell_values)
    Schedules::AssignmentSyncService.new(entry: entry).call

    redirect_to painel_schedule_month_path(@schedule, month: entry.month), notice: "Linha adicionada."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to painel_schedule_month_path(@schedule, month: month), alert: "Erro ao adicionar: #{e.message}"
  end

  def destroy
    month = params[:month]
    entry = @schedule.schedule_entries.find(params[:id])
    entry.destroy
    redirect_to painel_schedule_month_path(@schedule, month: month), notice: "Linha removida."
  end

  private

  def set_schedule
    scope = current_user.church.schedules
    scope = scope.where(departament_id: current_user.departament_ids) unless current_user.admin?
    @schedule = scope.find(params[:schedule_id])
    authorize @schedule, :update?
  end
end
