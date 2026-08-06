class ChurchesController < ApplicationController
  before_action :set_church, only: %i[ show edit update ]

  # GET /churches or /churches.json
  def index
    authorize Church
    @churches = policy_scope(Church)
  end

  # GET /churches/1 or /churches/1.json
  def show
  end

  # GET /churches/new
  def new
    @church = Church.new
    authorize @church
  end

  # GET /churches/1/edit
  def edit
  end

  # POST /churches or /churches.json
  def create
    @church = Church.new(church_params)
    authorize @church

    respond_to do |format|
      if @church.save
        format.html { redirect_to @church, notice: t(".success") }
        format.json { render :show, status: :created, location: @church }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @church.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /churches/1 or /churches/1.json
  def update
    respond_to do |format|
      if @church.update(church_params)
        format.html { redirect_to @church, notice: t(".success"), status: :see_other }
        format.json { render :show, status: :ok, location: @church }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @church.errors, status: :unprocessable_entity }
      end
    end
  end

  # Sem exclusão física: uma Church carrega toda a cadeia do tenant
  # (departamentos, usuários, eventos, escalas...) via dependent: :destroy —
  # desativar uma congregação é feito por Settings::CongregationToggleStatusService.
  # ChurchPolicy#destroy? já era sempre false; a ação nem era alcançável.

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_church
      @church = policy_scope(Church).find(params.expect(:id))
      authorize @church
    end

    # Only allow a list of trusted parameters through.
    def church_params
      params.fetch(:church, {})
    end
end
