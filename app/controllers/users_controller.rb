class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /panel/members
  def index
    authorize User
    departaments = visible_departaments
    scope = Users::IndexQuery.new(
      scope: policy_scope(User).order_pending_first,
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
    @user = current_user.church.users.build
    authorize @user
    save_member
  end

  def update
    save_member
  end


  # DELETE /users/1
  # Soft delete (mesmo caminho de Settings::UserRemoveService) — nunca
  # apaga fisicamente o membro, preserva histórico de escalas/eventos/auditoria.
  def destroy
    result = Settings::UserRemoveService.call(user: @user, performed_by: current_user)

    case result
    in Success(user)
      redirect_to panel_members_path, notice: t(".success"), status: :see_other
    in Failure(user)
      redirect_to panel_members_path, alert: user.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
    authorize @user
  end

  # Admins see every department (own church + congregations for the Sede);
  # leaders only the ones they belong to.
  def visible_departaments
    policy_scope(Departament).order(:name)
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :birth_date, :position, :status,
      :departament_id, :access_enabled, :password, :password_confirmation, :role,
      access_profile_ids: [], led_departament_ids: [])
  end

  def save_member
    result = Access::MemberSaveService.call(church: current_user.church, params: user_params,
      performed_by: current_user, user: @user)
    case result
    in Success(user)
      redirect_to panel_members_path(preserve_filters), notice: "Membro salvo com sucesso.", status: :see_other
    in Failure(user)
      redirect_to panel_members_path(preserve_filters), alert: user.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # Preserve current filter params when redirecting back to index
  def preserve_filters
    params.permit(:q, :role, :dept, :page, :per).to_h
  end
end
