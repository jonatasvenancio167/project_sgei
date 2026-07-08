class FormsController < ApplicationController
  before_action :set_form, only: %i[show edit update destroy builder statistics reorder_fields toggle_active]

  def index
    forms = current_user.church.forms.not_deleted.includes(:departament, :form_responses)

    unless current_user.admin?
      dept_ids = current_user.departament_ids
      forms = forms.where(departament_id: dept_ids + [nil])
    end

    @pagy, @forms = pagy(forms.order(created_at: :desc), limit: 8)
  end

  def show
    @tab = params[:tab] || "overview"
    @form_fields = @form.form_fields
    @pagy, @responses = pagy(@form.form_responses.order(created_at: :desc), limit: 20)
    @stats = build_statistics if @tab == "statistics"
  end

  def builder
    @form_fields = @form.form_fields
  end

  def statistics
    redirect_to form_path(@form, tab: "statistics")
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

    if @form.save
      redirect_to builder_form_path(@form), notice: "Formulário criado! Agora configure os campos."
    else
      @departaments = available_departaments
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @form.update(form_params)
      redirect_to @form, notice: "Formulário atualizado com sucesso."
    else
      @departaments = available_departaments
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @form.update!(deleted_at: Time.current, active: false)
    redirect_to forms_path, notice: "Formulário removido com sucesso."
  end

  def toggle_active
    @form.update!(active: !@form.active?)
    redirect_back fallback_location: form_path(@form),
                  notice: "Formulário #{@form.active? ? 'aberto' : 'encerrado'}."
  end

  def reorder_fields
    ids = params[:ids] || []
    ids.each_with_index do |id, index|
      @form.form_fields.where(id: id).update_all(position: index)
    end
    head :ok
  end

  private

  def set_form
    @form = current_user.church.forms.not_deleted.find(params[:id])
  end

  def form_params
    params.require(:form).permit(:title, :description, :active, :departament_id, :limit, :event_id, :banner_url)
  end

  def available_departaments
    current_user.admin? ? current_user.church.departaments : current_user.departaments
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
