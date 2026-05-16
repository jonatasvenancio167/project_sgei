class CalendarioController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    
    # Range for the month view
    start_of_month = @date.beginning_of_month
    end_of_month = @date.end_of_month
    
    @events = Event.where(start_date: start_of_month..end_of_month)
                   .includes(:departament)
                   .order(start_date: :asc)

    # Filter events based on user permissions
    unless @user.admin?
      @events = @events.where(departament_id: @user.departament_ids + [nil])
    end

    @dept_colors = {
      "Louvor" => "bg-primary",
      "Jovens" => "bg-chart-3",
      "Geral" => "bg-primary-soft",
      "Diaconia" => "bg-chart-4",
      "Ensino" => "bg-chart-2",
      "Kids" => "bg-primary-soft"
    }
  end
end
