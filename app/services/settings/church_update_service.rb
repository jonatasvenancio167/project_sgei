module Settings
  class ChurchUpdateService
    Result = Struct.new(:success?, :church, :errors, keyword_init: true)

    def initialize(church:, params:, performed_by:)
      @church = church
      @params = params
      @performed_by = performed_by
    end

    def call
      if church.update(params)
        Audit::RecordService.new(
          church: church, user: performed_by,
          module_key: "settings", action: "Atualizou os dados da instituição",
          detail: church.name
        ).call
        Result.new(success?: true, church: church)
      else
        Result.new(success?: false, church: church, errors: church.errors)
      end
    end

    private

    attr_reader :church, :params, :performed_by
  end
end
