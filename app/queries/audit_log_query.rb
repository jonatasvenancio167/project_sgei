class AuditLogQuery
  def initialize(church:, filters: {})
    @church = church
    @filters = filters
  end

  def call
    scope = church.audit_logs.includes(:user).recent_first
    scope = filter_by_module(scope)
    scope = filter_by_start_date(scope)
    filter_by_end_date(scope)
  end

  private

  attr_reader :church, :filters

  def filter_by_module(scope)
    return scope if filters[:module_key].blank? || filters[:module_key] == "all"

    scope.where(module_key: filters[:module_key])
  end

  def filter_by_start_date(scope)
    date = parse_date(filters[:start_date])
    date ? scope.where(created_at: date.beginning_of_day..) : scope
  end

  def filter_by_end_date(scope)
    date = parse_date(filters[:end_date])
    date ? scope.where(created_at: ..date.end_of_day) : scope
  end

  def parse_date(value)
    return if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
