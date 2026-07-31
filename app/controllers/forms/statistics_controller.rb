module Forms
  class StatisticsController < ApplicationController
    def show
      form = policy_scope(Form).not_deleted.find(params[:form_id])
      authorize form, :statistics?
      redirect_to form_path(form, tab: "statistics")
    end
  end
end
