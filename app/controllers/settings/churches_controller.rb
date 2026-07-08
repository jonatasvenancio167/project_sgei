module Settings
  class ChurchesController < BaseController
    # PATCH /settings/church
    def update
      result = Settings::ChurchUpdateService.new(
        church: current_church,
        params: church_params,
        performed_by: current_user
      ).call

      if result.success?
        redirect_to painel_settings_path(section: "church"), notice: "Alterações salvas com sucesso."
      else
        redirect_to painel_settings_path(section: "church"), alert: result.errors.full_messages.to_sentence
      end
    end

    private

    def church_params
      params.require(:church).permit(
        :name, :display_name, :cnpj, :email, :phone, :website, :founded_at,
        :church_type, :timezone, :status, :primary_color, :responsible_name,
        address_attributes: %i[street number complement neighborhood city state zip_code]
      )
    end
  end
end
