class MemberchipsController < ApplicationController
  before_action :set_memberchip, only: %i[ show edit update destroy ]

  # GET /memberchips or /memberchips.json
  def index
    @memberchips = Memberchip.all
  end

  # GET /memberchips/1 or /memberchips/1.json
  def show
  end

  # GET /memberchips/new
  def new
    @memberchip = Memberchip.new
  end

  # GET /memberchips/1/edit
  def edit
  end

  # POST /memberchips or /memberchips.json
  def create
    @memberchip = Memberchip.new(memberchip_params)

    respond_to do |format|
      if @memberchip.save
        format.html { redirect_to @memberchip, notice: "Memberchip was successfully created." }
        format.json { render :show, status: :created, location: @memberchip }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @memberchip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /memberchips/1 or /memberchips/1.json
  def update
    respond_to do |format|
      if @memberchip.update(memberchip_params)
        format.html { redirect_to @memberchip, notice: "Memberchip was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @memberchip }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @memberchip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberchips/1 or /memberchips/1.json
  def destroy
    @memberchip.destroy!

    respond_to do |format|
      format.html { redirect_to memberchips_path, notice: "Memberchip was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_memberchip
      @memberchip = Memberchip.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def memberchip_params
      params.fetch(:memberchip, {})
    end
end
