module Settings
  class UsersController < BaseController
    # POST /settings/users
    def create
      result = Settings::UserInviteService.new(
        church: current_church,
        params: user_params,
        performed_by: current_user
      ).call

      if result.success?
        redirect_to users_section_path, notice: "#{result.user.name} convidado com sucesso."
      else
        redirect_to users_section_path, alert: result.errors.full_messages.to_sentence
      end
    end

    # PATCH /settings/users/:id/toggle_status
    def toggle_status
      result = Settings::UserToggleStatusService.new(
        user: set_user,
        performed_by: current_user
      ).call

      if result.success?
        status_label = result.user.status_active? ? "ativado" : "desativado"
        redirect_to users_section_path, notice: "Acesso de #{result.user.name} #{status_label}."
      else
        redirect_to users_section_path, alert: result.errors.full_messages.to_sentence
      end
    end

    # DELETE /settings/users/:id
    def destroy
      result = Settings::UserRemoveService.new(
        user: set_user,
        performed_by: current_user
      ).call

      if result.success?
        redirect_to users_section_path, notice: "#{result.user.name} removido.", status: :see_other
      else
        redirect_to users_section_path, alert: result.errors.full_messages.to_sentence, status: :see_other
      end
    end

    private

    def set_user
      current_church.users.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :phone, :role, :status, :password, :password_confirmation)
    end

    def users_section_path
      painel_settings_path(params.permit(:q, :role, :status).to_h.merge(section: "users"))
    end
  end
end
