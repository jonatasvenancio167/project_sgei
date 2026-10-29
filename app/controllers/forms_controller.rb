class FormsController < ApplicationController
  before_action :set_form, only: %i[show edit update destroy]

  def index
    authorize Form
    forms = policy_scope(Form).not_deleted.includes(:departament, :form_responses)

    @pagy, @forms = pagy(forms.order(created_at: :desc), limit: 8)
  end

  def show
    @tab = params[:tab] || "overview"
    @form_fields = @form.form_fields
    @pagy, @responses = pagy(policy_scope(FormResponse).where(form: @form).order(created_at: :desc), limit: 20)
    if @tab == "statistics"
      authorize @form, :statistics?
      @stats = build_statistics
    end
  end

  def new
    @form = Form.new
    @departaments = available_departaments
  end

  def edit
    @departaments = available_departaments
  end

  def create
    @form = current_user.church.forms.build(form_params)
    authorize @form

    if @form.save
      redirect_to form_builder_path(@form), notice: t(".success")
    else
      @departaments = available_departaments
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @form.update(form_params)
      redirect_to @form, notice: t(".success")
    else
      @departaments = available_departaments
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @form.update!(deleted_at: Time.current, active: false)
    redirect_to forms_path, notice: t(".success")
  end

  private

  def set_form
    @form = policy_scope(Form).not_deleted.find(params[:id])
    authorize @form
  end

  def form_params
    params.require(:form).permit(:title, :description, :active, :departament_id, :limit, :event_id, :banner_url)
  end

  def available_departaments
    policy_scope(Departament)
  end

  def build_statistics
    @form.form_fields.each_with_object({}) do |field, stats|
      answers = FormAnswer.where(form_field: field).pluck(:value).reject(&:blank?)
      stats[field.id] = if field.choice_field?
        tally = Hash.new(0)
        answers.each do |val|
          val.split(", ").each { |v| tally[v.strip] += 1 }
        end
        { type: :choices, total: answers.size, tally: tally.sort_by { |_, v| -v } }
      else
        { type: :text, total: answers.size, sample: answers.first(10) }
      end
    end
  end
end
