module Schedules
  class UpdateService
    Result = Struct.new(:success?, :schedule, :errors, keyword_init: true)

    def initialize(schedule:, params:, columns:)
      @schedule = schedule
      @params = params
      @columns = Array(columns).filter_map do |col|
        name = col["name"].to_s.strip
        type = col["type"].to_s.strip
        next if name.blank?
        { name: name, type: ScheduleColumn::COLUMN_TYPES.key?(type) ? type : "text" }
      end
    end

    def call
      if columns.empty?
        schedule.errors.add(:base, "Adicione ao menos uma coluna")
        return Result.new(success?: false, schedule: schedule, errors: schedule.errors)
      end

      if columns.none? { |col| col[:type] == "member" }
        schedule.errors.add(:base, "Adicione ao menos uma coluna do tipo Membro para vincular e notificar os escalados")
        return Result.new(success?: false, schedule: schedule, errors: schedule.errors)
      end

      ActiveRecord::Base.transaction do
        schedule.update!(params)

        existing = schedule.schedule_columns.order(:position).to_a
        columns.each_with_index do |col, index|
          if existing[index]
            existing[index].update!(name: col[:name], column_type: col[:type], position: index)
          else
            schedule.schedule_columns.create!(name: col[:name], column_type: col[:type], position: index)
          end
        end
        existing[columns.size..]&.each(&:destroy)
      end

      Result.new(success?: true, schedule: schedule)
    rescue ActiveRecord::RecordInvalid
      Result.new(success?: false, schedule: schedule, errors: schedule.errors)
    end

    private

    attr_reader :schedule, :params, :columns
  end
end
