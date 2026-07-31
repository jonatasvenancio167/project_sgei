module Schedules
  # Groups the derived data the schedule month view needs beyond the
  # @schedule itself: decorator, grid columns/entries and member roster.
  class ShowPresenter
    attr_reader :month, :decorator, :columns, :entries,
                :dept_members, :member_counts, :users_map,
                :scheduled_members, :unscheduled_members

    def initialize(schedule:, month:, view_context:, church:)
      @schedule = schedule
      @month = month
      @decorator = ScheduleDecorator.new(schedule, view_context)
      @columns = schedule.schedule_columns.order(:position)
      @entries = schedule.schedule_entries.where(month: month).order(:date, :position)
      remap_orphaned_entries

      @dept_members = department_or_church_members(church)

      member_col_ids = columns.select { |c| c.column_type == "member" }.map { |c| c.id.to_s }
      @member_counts = build_member_counts(member_col_ids)
      @users_map = member_col_ids.any? ? User.where(id: member_counts.keys).index_by { |u| u.id.to_s } : {}

      scheduled = member_counts.keys
      @scheduled_members = dept_members.select { |m| scheduled.include?(m.id.to_s) }
      @unscheduled_members = dept_members.reject { |m| scheduled.include?(m.id.to_s) }
    end

    private

    attr_reader :schedule

    def department_or_church_members(church)
      members = schedule.departament.users.where(deleted_at: nil).order(:name)
      members.any? ? members : church.users.where(deleted_at: nil).order(:name)
    end

    def build_member_counts(member_col_ids)
      counts = Hash.new(0)
      entries.each do |entry|
        member_col_ids.each { |cid| counts[entry.cell_values[cid]] += 1 if entry.cell_values[cid].present? }
      end
      counts
    end

    def remap_orphaned_entries
      col_ids = columns.map { |c| c.id.to_s }
      return if col_ids.empty?

      entries.each do |entry|
        next if entry.cell_values.blank?
        next if (entry.cell_values.keys & col_ids).any?

        sorted_values = entry.cell_values.sort_by { |k, _| k.to_i }.map { |_, v| v }
        new_values = col_ids.each_with_index.with_object({}) { |(id, i), h| h[id] = sorted_values[i] }
        entry.update_columns(cell_values: new_values)
      end
    end
  end
end
