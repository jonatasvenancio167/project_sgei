class WelcomeRecordsController < ApplicationController
  include Paginatable

  before_action :set_welcome_record, only: %i[update destroy]

  # GET /panel/welcome
  def index
    authorize :welcome_record, :index?

    query = WelcomeRecordQuery.new(params, user: current_user)
    @pagy, @welcome_records = pagy(query.call, limit: per_page)
    @decorator = ::WelcomeRecords::IndexDecorator.new(
      @welcome_records, query.summary, params, current_user, view_context, total_count: @pagy.count
    )
    @new_welcome_record = WelcomeRecord.new(visitor_type: :visitor, service: WelcomeRecord::SERVICES.first)
  end

  # POST /panel/welcome (modal "Registrar visita")
  def create
    @welcome_record = current_user.church.welcome_records.build(welcome_record_params)
    @welcome_record.registered_by = current_user
    authorize @welcome_record

    if @welcome_record.save
      redirect_to panel_welcome_path(preserve_filters.merge(tab: "hoje")),
                  notice: t(".success", name: @welcome_record.name)
    else
      redirect_to panel_welcome_path(preserve_filters),
                  alert: @welcome_record.errors.full_messages.to_sentence
    end
  end

  # PATCH /panel/welcome/:id (modal "Editar registro")
  def update
    if @welcome_record.update(welcome_record_params)
      redirect_to panel_welcome_path(preserve_filters),
                  notice: t(".success"), status: :see_other
    else
      redirect_to panel_welcome_path(preserve_filters),
                  alert: @welcome_record.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # DELETE /panel/welcome/:id
  def destroy
    @welcome_record.destroy!
    redirect_to panel_welcome_path(preserve_filters), notice: t(".success"), status: :see_other
  end

  private

  def set_welcome_record
    @welcome_record = current_user.church.welcome_records.find(params[:id])
    authorize @welcome_record
  end

  def welcome_record_params
    params.require(:welcome_record).permit(:name, :visitor_type, :congregation, :city, :phone, :service, :notes)
  end

  # Preserve current tab/filter params when redirecting back to index
  def preserve_filters
    params.permit(:tab, :q, :type, :service, :start_date, :end_date, :members_only, :page, :per).to_h
  end
end
