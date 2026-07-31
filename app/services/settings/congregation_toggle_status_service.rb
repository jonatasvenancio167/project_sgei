module Settings
  class CongregationToggleStatusService < BaseService
    def initialize(congregation:, performed_by:)
      @congregation = congregation
      @performed_by = performed_by
    end

    def call
      new_status = congregation.status_active? ? "inactive" : "active"

      if congregation.update(status: new_status)
        Audit::RecordService.call(
          church: congregation.parent_church, user: performed_by,
          module_key: "congregations",
          action: new_status == "active" ? "Ativou congregação" : "Desativou congregação",
          detail: congregation.name
        )
        Success(congregation)
      else
        Failure(congregation)
      end
    end

    private

    attr_reader :congregation, :performed_by
  end
end
