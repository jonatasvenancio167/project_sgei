module Forms
  class ActivationsController < ApplicationController
    def update
      form = policy_scope(Form).not_deleted.find(params[:form_id])
      authorize form, :toggle_active?

      form.update!(active: !form.active?)
      redirect_back fallback_location: form_path(form),
                    notice: form.active? ? t(".opened") : t(".closed")
    end
  end
end
