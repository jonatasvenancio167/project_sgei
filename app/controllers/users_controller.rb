class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /painel/membros
  def index
    authorize User
    @departaments = visible_departaments
    scope = current_user.church.users.order(:name)

    # Leaders only see members of the departments they lead
    if current_user.leader?
      scope = scope.joins(:memberchips)
                   .where(memberchips: { departament_id: @departaments.select(:id) })
                   .distinct
    end

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
      # A leader's scope is already restricted to their departments, so
      # "sem departamento" can never match anyone there.
      scope = current_user.leader? ? scope.none : scope.left_outer_joins(:memberchips).where(memberchips: { id: nil })
    when "todos", "", nil
      # no filter
    else
      dept = @departaments.find_by(id: params[:dept])
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
    authorize @user
    @user.password = password
    @user.password_confirmation = password
    @user.role ||= :member

    if @user.save
      sync_departament(@user)
      redirect_to painel_membros_path(preserve_filters), notice: "#{@user.name} adicionado com sucesso."
    else
      errors = @user.errors.full_messages.to_sentence
      redirect_to painel_membros_path(preserve_filters), alert: errors
    end
  end

  # PATCH/PUT /users/1  (used by the "Editar membro" modal on /painel/membros)
  def update
    if @user.update(user_params)
      sync_departament(@user)
      redirect_to painel_membros_path(preserve_filters), notice: "#{@user.name} atualizado com sucesso.", status: :see_other
    else
      redirect_to painel_membros_path(preserve_filters), alert: @user.errors.full_messages.to_sentence, status: :see_other
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
    authorize @user
  end

  # Admins see every department; leaders only the ones they belong to.
  def visible_departaments
    depts = current_user.church.departaments.order(:name)
    return depts unless current_user.leader?

    depts.where(id: current_user.memberchips.select(:departament_id))
  end

  def user_params
    permitted = %i[name email phone birth_date]
    permitted << :role if current_user.admin?
    params.require(:user).permit(*permitted)
  end

  # The department select in the members modals edits the user's primary
  # department, which lives in memberchips (users has no departament_id).
  # Other department memberships are left untouched.
  def sync_departament(user)
    return unless params[:user]&.key?(:departament_id)

    new_dept = current_user.church.departaments.find_by(id: params[:user][:departament_id])
    current_dept = user.primary_department
    return if current_dept&.id == new_dept&.id

    user.memberchips.find_by(departament: current_dept)&.destroy if current_dept
    user.memberchips.find_or_create_by(departament: new_dept) { |m| m.role = user.leader? ? :leader : :member } if new_dept
  end

  # Preserve current filter params when redirecting back to index
  def preserve_filters
    params.permit(:q, :role, :dept, :page, :per).to_h
  end
end
