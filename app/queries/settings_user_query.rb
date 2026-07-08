class SettingsUserQuery
  def initialize(church:, filters: {})
    @church = church
    @filters = filters
  end

  def call
    scope = church.users.where(deleted_at: nil).order(:name)
    scope = filter_by_term(scope)
    scope = filter_by_role(scope)
    filter_by_status(scope)
  end

  private

  attr_reader :church, :filters

  def filter_by_term(scope)
    term = filters[:q].to_s.strip
    return scope if term.blank?

    like = "%#{term}%"
    scope.where("name ILIKE ? OR email ILIKE ?", like, like)
  end

  def filter_by_role(scope)
    role = filters[:role].to_s
    return scope if role.blank? || role == "all" || User.roles.exclude?(role)

    scope.where(role: role)
  end

  def filter_by_status(scope)
    status = filters[:status].to_s
    return scope if status.blank? || status == "all" || User.statuses.exclude?(status)

    scope.where(status: status)
  end
end
