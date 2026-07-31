module Settings
  class CongregationsController < BaseController
    # POST /settings/congregations
    def create
      result = Settings::CongregationCreateService.call(
        parent_church: current_church,
        params: congregation_params,
        performed_by: current_user
      )

      case result
      in Success(_)
        redirect_to panel_settings_path(section: "congregations"), notice: t(".success")
      in Failure(congregation)
        redirect_to panel_settings_path(section: "congregations"), alert: congregation.errors.full_messages.to_sentence
      end
    end

    private

    def congregation_params
      params.require(:congregation).permit(:name, :church_type, :status, :responsible_name,
                                           address_attributes: %i[city state])
    end
  end
end
