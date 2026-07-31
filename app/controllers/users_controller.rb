class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /panel/members
  def index
    authorize User
    departaments = visible_departaments
    scope = Users::IndexQuery.new(
      scope: policy_scope(User).order(:name),
      user: current_user,
      departaments: departaments,
      params: params
    ).call

    @presenter = Users::IndexPresenter.new(scope: scope, departaments: departaments, params: params)
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

  # POST /users  (used by the "Novo membro" modal on /panel/members)
  def create
    password = SecureRandom.hex(8)
    @user = current_user.church.users.build(user_params)
    authorize @user
    @user.password = password
    @user.password_confirmation = password
    @user.role ||= :member

    if @user.save
      sync_departament(@user)
      redirect_to panel_members_path(preserve_filters), notice: t(".success", name: @user.name)
    else
      errors = @user.errors.full_messages.to_sentence
      redirect_to panel_members_path(preserve_filters), alert: errors
    end
  end

  # PATCH/PUT /users/1  (used by the "Editar membro" modal on /panel/members)
  def update
    if @user.update(user_params)
      sync_departament(@user)
      redirect_to panel_members_path(preserve_filters), notice: t(".success", name: @user.name), status: :see_other
    else
      redirect_to panel_members_path(preserve_filters), alert: @user.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy!
    redirect_to panel_members_path, notice: t(".success"), status: :see_other
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
    authorize @user
  end

  # Admins see every department (own church + congregations for the Sede);
  # leaders only the ones they belong to.
  def visible_departaments
    depts = policy_scope(Departament).order(:name)
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
