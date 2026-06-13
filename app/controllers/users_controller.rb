class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /painel/membros
  def index
    @departaments = current_user.church.departaments.order(:name)
    scope = current_user.church.users.order(:name)

    # — Search query (name / email / phone) ——————————————————————————————
    if (q = params[:q].to_s.strip).present?
      like = "%#{q}%"
      scope = scope.where("name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", like, like, like)
    end

    # — Role filter ————————————————————————————————————————————————————————
    if params[:role].present? && params[:role] != "todos"
      scope = scope.where(role: params[:role])
    end

    # — Department filter ——————————————————————————————————————————————————
    case params[:dept]
    when "sem"
      scope = scope.left_outer_joins(:memberchips).where(memberchips: { id: nil })
    when "todos", "", nil
      # no filter
    else
      dept = current_user.church.departaments.find_by(id: params[:dept])
      scope = scope.joins(:memberchips).where(memberchips: { departament_id: dept&.id }) if dept
    end

    # — Pagination ————————————————————————————————————————————————————————
    @per       = [params[:per].to_i, 10].max.then { |v| [10, 25, 50].include?(v) ? v : 10 }
    @page      = [params[:page].to_i, 1].max
    @total     = scope.count
    @total_pages = [(@total.to_f / @per).ceil, 1].max
    @page      = [@page, @total_pages].min

    @users = scope.offset((@page - 1) * @per).limit(@per)
    @new_user = User.new
  end

  # GET /users/1
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users  (used by the "Novo membro" modal on /painel/membros)
  def create
    password = SecureRandom.hex(8)
    @user = current_user.church.users.build(user_params)
    @user.password = password
    @user.password_confirmation = password
    @user.role ||= :member

    if @user.save
      redirect_to painel_membros_path(preserve_filters), notice: "#{@user.name} adicionado com sucesso."
    else
      errors = @user.errors.full_messages.to_sentence
      redirect_to painel_membros_path(preserve_filters), alert: errors
    end
  end

  # PATCH/PUT /users/1
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: "Membro atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy!
    redirect_to painel_membros_path, notice: "Membro removido.", status: :see_other
  end

  private

  def set_user
    @user = current_user.church.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :role, :departament_id)
  end

  # Preserve current filter params when redirecting back to index
  def preserve_filters
    params.permit(:q, :role, :dept, :page, :per).to_h
  end
end
