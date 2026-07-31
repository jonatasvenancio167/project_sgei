module Forms
  class BuildersController < ApplicationController
    def show
      @form = policy_scope(Form).not_deleted.find(params[:form_id])
      authorize @form, :builder?
      @form_fields = @form.form_fields
    end
  end
end
