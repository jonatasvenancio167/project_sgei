class CalendarController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :calendar, :index?
    @user = current_user
    @date = params[:date] ? Date.parse(params[:date]) : Date.current

    # Range for the month view
    start_of_month = @date.beginning_of_month
    end_of_month = @date.end_of_month

    # Só aprovados (e arquivados, somente leitura) entram no calendário —
    # rascunho/aguardando aprovação/recusado/cancelado nunca aparecem (§8).
    @events = policy_scope(Event)
                   .where(start_date: start_of_month..end_of_month, status: %i[approved archived])
                   .includes(:departament)
                   .order(start_date: :asc)

    # Filter events based on user permissions
    unless @user.admin?
      @events = @events.where(departament_id: @user.departament_ids + [nil])
    end
  end
end
