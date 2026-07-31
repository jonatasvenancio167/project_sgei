module Forms
  class FieldOrderingsController < ApplicationController
    def update
      form = policy_scope(Form).not_deleted.find(params[:form_id])
      authorize form, :reorder_fields?

      Array(params[:ids]).each_with_index do |id, index|
        form.form_fields.where(id: id).update_all(position: index)
      end
      head :ok
    end
  end
end
