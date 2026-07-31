module Settings
  class ChurchUpdateService < BaseService
    def initialize(church:, params:, performed_by:)
      @church = church
      @params = params
      @performed_by = performed_by
    end

    def call
      if church.update(params)
        Audit::RecordService.call(
          church: church, user: performed_by,
          module_key: "settings", action: "Atualizou os dados da instituição",
          detail: church.name
        )
        Success(church)
      else
        Failure(church)
      end
    end

    private

    attr_reader :church, :params, :performed_by
  end
end
