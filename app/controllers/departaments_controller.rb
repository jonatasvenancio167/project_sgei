class DepartamentsController < ApplicationController
  before_action :set_departament, only: %i[ show edit update destroy ]

  # GET /departaments or /departaments.json
  def index
    authorize Departament
    @departaments = policy_scope(Departament).order(:name)
    # Non-admins only see the departments they belong to
    @departaments = @departaments.where(id: current_user.departament_ids) unless current_user.admin?
    @church_users = current_user.church.users.order(:name)
    @new_departament = Departament.new
  end

  # GET /departaments/1 or /departaments/1.json
  def show
  end

  # GET /departaments/new
  def new
    @departament = Departament.new
  end

  # GET /departaments/1/edit
  def edit
  end

  # POST /departaments or /departaments.json
  def create
    authorize Departament.new(church: current_user.church)

    result = Departaments::CreateService.call(
      church: current_user.church,
      params: departament_params,
      member_ids: params[:member_ids],
      leader_id: params[:leader_id]
    )

    respond_to do |format|
      case result
      in Success(departament)
        format.html { redirect_to departaments_path, notice: t(".success") }
        format.json { render :show, status: :created, location: departament }
      in Failure(departament)
        @departaments = current_user.church.departaments.order(:name)
        @church_users = current_user.church.users.order(:name)
        @new_departament = departament
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: departament.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /departaments/1 or /departaments/1.json
  def update
    respond_to do |format|
      if @departament.update(departament_params)
        format.html { redirect_to departaments_path, notice: t(".success"), status: :see_other }
        format.json { render :show, status: :ok, location: @departament }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @departament.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /departaments/1 or /departaments/1.json
  def destroy
    @departament.destroy!

    respond_to do |format|
      format.html { redirect_to departaments_path, notice: t(".success"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_departament
    @departament = policy_scope(Departament).find(params[:id])
    authorize @departament
  end

  # Only allow a list of trusted parameters through.
  def departament_params
    params.require(:departament).permit(:name, :description, :color, :icon)
  end
end
