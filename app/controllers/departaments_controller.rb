class DepartamentsController < ApplicationController
  before_action :set_departament, only: %i[ show edit update destroy add_members ]

  # GET /departaments or /departaments.json
  def index
    @departaments = current_user.church.departaments.order(:name)
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
    @departament = current_user.church.departaments.build(departament_params)

    respond_to do |format|
      if @departament.save
        # Handle initial members and leader
        member_ids = Array(params[:member_ids]).map(&:to_i)
        leader_id = params[:leader_id].presence&.to_i

        member_ids.each do |user_id|
          role = (user_id == leader_id) ? :leader : :member
          @departament.memberchips.create!(user_id: user_id, role: role)

          # Update user's role to leader if made leader and not admin
          if role == :leader
            user = User.find(user_id)
            user.update!(role: :leader) unless user.admin?
          end
        end

        format.html { redirect_to departaments_path, notice: "Departamento criado com sucesso." }
        format.json { render :show, status: :created, location: @departament }
      else
        @departaments = current_user.church.departaments.order(:name)
        @church_users = current_user.church.users.order(:name)
        @new_departament = @departament
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @departament.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /departaments/1 or /departaments/1.json
  def update
    respond_to do |format|
      if @departament.update(departament_params)
        format.html { redirect_to departaments_path, notice: "Departamento atualizado com sucesso.", status: :see_other }
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
      format.html { redirect_to departaments_path, notice: "Departamento removido com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # POST /departaments/1/add_members
  def add_members
    kind = params[:kind]
    notice = ""

    if kind == "existing"
      user_ids = Array(params[:user_ids]).map(&:to_i)
      added_count = 0
      user_ids.each do |u_id|
        memberchip = @departament.memberchips.build(user_id: u_id, role: :member)
        if memberchip.save
          added_count += 1
        end
      end
      notice = "#{added_count} #{added_count == 1 ? 'membro vinculado' : 'membros vinculados'} com sucesso."
    elsif kind == "new"
      name = params[:name]
      email = params[:email].presence
      phone = params[:phone]
      make_leader = params[:make_leader] == "1" || params[:make_leader] == "true"

      # Find or create user
      user = User.find_by(id: params[:user_ids])
      if user.nil?
        password = SecureRandom.hex(8)
        user = User.create!(
          name: name,
          email: email,
          phone: phone,
          password: password,
          password_confirmation: password,
          church: current_user.church,
          role: make_leader ? :leader : :member
        )
      else
        if make_leader && !user.admin?
          user.update!(role: :leader)
        end
      end

      # Link to department
      memberchip = @departament.memberchips.build(user: user, role: make_leader ? :leader : :member)
      if memberchip.save
        notice = "#{user.name} adicionado com sucesso."
      else
        notice = memberchip.errors.full_messages.to_sentence
      end
    end

    respond_to do |format|
      format.html { redirect_to departaments_path, notice: notice }
      format.json { render json: { success: true, notice: notice } }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_departament
    @departament = current_user.church.departaments.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def departament_params
    params.require(:departament).permit(:name, :description, :color, :icon)
  end
end
