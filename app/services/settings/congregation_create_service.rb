module Settings
  class CongregationCreateService
    Result = Struct.new(:success?, :congregation, :errors, keyword_init: true)

    def initialize(parent_church:, params:, performed_by:)
      @parent_church = parent_church
      @params = params
      @performed_by = performed_by
    end

    def call
      congregation = parent_church.congregations.build(params)
      congregation.slug = generate_slug(congregation.name)
      congregation.timezone = parent_church.timezone
      congregation.primary_color = parent_church.primary_color
      congregation.church_type = "congregation" if congregation.type_headquarters?

      if congregation.save
        Audit::RecordService.new(
          church: parent_church, user: performed_by,
          module_key: "congregations", action: "Criou congregação",
          detail: congregation.name
        ).call
        Result.new(success?: true, congregation: congregation)
      else
        Result.new(success?: false, congregation: congregation, errors: congregation.errors)
      end
    end

    private

    attr_reader :parent_church, :params, :performed_by

    def generate_slug(name)
      base = name.to_s.parameterize.presence || "congregacao"
      slug = base
      slug = "#{base}-#{SecureRandom.hex(2)}" while Church.exists?(slug: slug)
      slug
    end
  end
end
