class FormFieldsController < ApplicationController
  before_action :set_form
  before_action :set_field, only: %i[update destroy]

  def create
    @field = @form.form_fields.build(field_params)
    @field.position = (@form.form_fields.maximum(:position) || -1) + 1
    @field.options = { "choices" => ["Opção 1"] } if @field.choice_field? && @field.choices.empty?

    respond_to do |format|
      if @field.save
        format.turbo_stream
        format.html { redirect_to builder_form_path(@form) }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("field_errors", partial: "form_fields/errors", locals: { field: @field }) }
        format.html { redirect_to builder_form_path(@form), alert: @field.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    respond_to do |format|
      if @field.update(field_params)
        format.turbo_stream
        format.html { redirect_to builder_form_path(@form) }
      else
        format.turbo_stream
        format.html { redirect_to builder_form_path(@form), alert: @field.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    @field.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("field_#{@field.id}") }
      format.html { redirect_to builder_form_path(@form) }
    end
  end

  private

  def set_form
    @form = current_user.church.forms.not_deleted.find(params[:form_id])
    authorize @form, :update?
  end

  def set_field
    @field = @form.form_fields.find(params[:id])
  end

  def field_params
    p = params.require(:form_field).permit(:label, :label_type, :required, :position, choices: [])
    choices = Array(p.delete(:choices)).map(&:strip).reject(&:blank?)
    p[:options] = %w[select radio checkbox].include?(p[:label_type]) ? { "choices" => choices } : {}
    p
  end
end
