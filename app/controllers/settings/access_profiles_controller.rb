module Settings
  class AccessProfilesController < BaseController
    def create
      authorize AccessProfile
      save_profile
    end

    def update
      @profile = policy_scope(AccessProfile).find(params[:id])
      authorize @profile
      save_profile
    end

    private

    def save_profile
      result = Access::ProfileSaveService.call(church: current_church, profile: @profile,
        params: params.require(:access_profile).permit(:name, :description), performed_by: current_user)
      case result
      in Success(profile)
        redirect_to panel_settings_path(section: "permissions", profile_id: profile.id), notice: "Perfil salvo com sucesso.", status: :see_other
      in Failure(profile)
        load_profile_page(profile)
        flash.now[:alert] = profile.errors.full_messages.to_sentence
        render "settings/show", status: :unprocessable_content
      end
    end

    def load_profile_page(profile)
      @church = current_church
      @section = "permissions"
      @profiles = @church.access_profiles.order(:name)
      @profile_form = profile
      @selected_profile = profile if profile.persisted?
    end
  end
end
