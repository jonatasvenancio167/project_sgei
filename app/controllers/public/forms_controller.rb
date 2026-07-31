class Public::FormsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "public"

  # Overrides ApplicationController's generic 404 with the branded public page.
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def show
    @form = Form.active.find_by!(slug: params[:slug])
    @form_fields = @form.form_fields
    @response = FormResponse.new
  end

  def submit
    @form = Form.active.find_by!(slug: params[:slug])

    result = FormSubmissionService.call(@form, submission_params)

    case result
    in Success(_)
      redirect_to public_form_success_path(@form.slug)
    in Failure(response)
      @form_fields = @form.form_fields
      @response = response
      render :show, status: :unprocessable_entity
    end
  end

  def success
    @form = Form.not_deleted.find_by!(slug: params[:slug])
  end

  private

  def render_not_found
    render "public/forms/not_found", status: :not_found
  end

  def submission_params
    params.permit(:guest_name, :guest_email, :guest_phone, answers: {})
  end
end
