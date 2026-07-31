module Schedules
  class CreateService < BaseService
    def initialize(church:, params:, columns:)
      @church = church
      @params = params
      @columns = Array(columns).filter_map do |col|
        name = col["name"].to_s.strip
        type = col["type"].to_s.strip
        next if name.blank?
        { name: name, type: ScheduleColumn::COLUMN_TYPES.key?(type) ? type : "text" }
      end
    end

    def call
      schedule = church.schedules.build(params)
      schedule.church = church

      if columns.empty?
        schedule.errors.add(:base, "Adicione ao menos uma coluna")
        return Failure(schedule)
      end

      if columns.none? { |col| col[:type] == "member" }
        schedule.errors.add(:base, "Adicione ao menos uma coluna do tipo Membro para vincular e notificar os escalados")
        return Failure(schedule)
      end

      ActiveRecord::Base.transaction do
        schedule.save!
        columns.each_with_index do |col, index|
          schedule.schedule_columns.create!(name: col[:name], column_type: col[:type], position: index)
        end
      end

      Success(schedule)
    rescue ActiveRecord::RecordInvalid
      Failure(schedule)
    end

    private

    attr_reader :church, :params, :columns
  end
end
