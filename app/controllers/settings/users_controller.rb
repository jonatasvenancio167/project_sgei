module Settings
  class UsersController < BaseController
    # POST /settings/users
    def create
      result = Settings::UserInviteService.call(
        church: current_church,
        params: user_params,
        performed_by: current_user
      )

      case result
      in Success(user)
        redirect_to users_section_path, notice: t(".success", name: user.name)
      in Failure(user)
        redirect_to users_section_path, alert: user.errors.full_messages.to_sentence
      end
    end

    # DELETE /settings/users/:id
    def destroy
      result = Settings::UserRemoveService.call(
        user: set_user,
        performed_by: current_user
      )

      case result
      in Success(user)
        redirect_to users_section_path, notice: t(".success", name: user.name), status: :see_other
      in Failure(user)
        redirect_to users_section_path, alert: user.errors.full_messages.to_sentence, status: :see_other
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
      panel_settings_path(params.permit(:q, :role, :status).to_h.merge(section: "users"))
    end
  end
end
