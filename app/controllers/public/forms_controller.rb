class Public::FormsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "public"

  def show
    @form = Form.active.find_by!(slug: params[:slug])
    @form_fields = @form.form_fields
    @response = FormResponse.new
  rescue ActiveRecord::RecordNotFound
    render "public/forms/not_found", status: :not_found
  end

  def submit
    @form = Form.active.find_by!(slug: params[:slug])

    result = FormSubmissionService.new(@form, submission_params).call

    if result.persisted?
      redirect_to public_form_success_path(@form.slug)
    else
      @form_fields = @form.form_fields
      @response = result
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render "public/forms/not_found", status: :not_found
  end

  def success
    @form = Form.not_deleted.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render "public/forms/not_found", status: :not_found
  end

  private

  def submission_params
    params.permit(:guest_name, :guest_email, :guest_phone, answers: {})
  end
end
