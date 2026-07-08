module Settings
  class CongregationsController < BaseController
    # POST /settings/congregations
    def create
      result = Settings::CongregationCreateService.new(
        parent_church: current_church,
        params: congregation_params,
        performed_by: current_user
      ).call

      if result.success?
        redirect_to painel_settings_path(section: "congregations"), notice: "Congregação adicionada com sucesso."
      else
        redirect_to painel_settings_path(section: "congregations"), alert: result.errors.full_messages.to_sentence
      end
    end

    # PATCH /settings/congregations/:id/toggle_status
    def toggle_status
      result = Settings::CongregationToggleStatusService.new(
        congregation: current_church.congregations.find(params[:id]),
        performed_by: current_user
      ).call

      if result.success?
        status_label = result.congregation.status_active? ? "ativada" : "desativada"
        redirect_to painel_settings_path(section: "congregations"), notice: "Congregação #{status_label}."
      else
        redirect_to painel_settings_path(section: "congregations"), alert: result.errors.full_messages.to_sentence
      end
    end

    private

    def congregation_params
      params.require(:congregation).permit(:name, :church_type, :status, :responsible_name,
                                           address_attributes: %i[city state])
    end
  end
end
