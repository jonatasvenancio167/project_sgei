module Settings
  class CongregationCreateService < BaseService
    def initialize(parent_church:, params:, performed_by:)
      @parent_church = parent_church
      @params = params
      @performed_by = performed_by
    end

    def call
      congregation = parent_church.congregations.build(params)
      congregation.slug = Church.generate_unique_slug(congregation.name)
      congregation.timezone = parent_church.timezone
      congregation.primary_color = parent_church.primary_color
      congregation.church_type = "congregation" if congregation.type_headquarters?

      if congregation.save
        Audit::RecordService.call(
          church: parent_church, user: performed_by,
          module_key: "congregations", action: "Criou congregação",
          detail: congregation.name
        )
        Success(congregation)
      else
        Failure(congregation)
      end
    end

    private

    attr_reader :parent_church, :params, :performed_by
  end
end
