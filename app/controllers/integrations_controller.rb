class IntegrationsController < ApplicationController
  before_action :set_integration, only: %i[ show edit update destroy ]

  # GET /integrations or /integrations.json
  def index
    authorize Integration
    @integrations = policy_scope(Integration)
  end

  # GET /integrations/1 or /integrations/1.json
  def show
  end

  # GET /integrations/new
  def new
    @integration = Integration.new
    authorize @integration
  end

  # GET /integrations/1/edit
  def edit
  end

  # POST /integrations or /integrations.json
  def create
    @integration = Integration.new(integration_params)
    @integration.church = current_user.church
    authorize @integration

    respond_to do |format|
      if @integration.save
        format.html { redirect_to @integration, notice: t(".success") }
        format.json { render :show, status: :created, location: @integration }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @integration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /integrations/1 or /integrations/1.json
  def update
    respond_to do |format|
      if @integration.update(integration_params)
        format.html { redirect_to @integration, notice: t(".success"), status: :see_other }
        format.json { render :show, status: :ok, location: @integration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @integration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /integrations/1 or /integrations/1.json
  def destroy
    @integration.destroy!

    respond_to do |format|
      format.html { redirect_to integrations_path, notice: t(".success"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_integration
      @integration = policy_scope(Integration).find(params.expect(:id))
      authorize @integration
    end

    # Only allow a list of trusted parameters through.
    def integration_params
      params.fetch(:integration, {})
    end
end
