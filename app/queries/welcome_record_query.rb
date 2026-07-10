# Welcome records (acolhimento) of the user's church for the active tab:
# "hoje" lists today's registrations; "historico" applies the filter bar
# (name, type, service, date range, converted-to-member). All filters run
# on welcome_records alone — no joins.
class WelcomeRecordQuery
  TABS = %w[hoje historico].freeze

  def initialize(params = {}, user:)
    @params = params
    @user = user
  end

  def call
    scoped.order(created_at: :desc)
  end

  def tab
    TABS.include?(params[:tab]) ? params[:tab] : TABS.first
  end

  # { total:, visitors:, brothers: } for the active tab, in a single grouped count.
  def summary
    counts = scoped.group(:visitor_type).count
    visitors = counts.fetch("visitor", 0)
    brothers = counts.fetch("brother", 0)
    { total: visitors + brothers, visitors: visitors, brothers: brothers }
  end

  private

  attr_reader :params, :user

  # Day boundaries follow the church's timezone (the app runs in UTC).
  def scoped
    in_church_zone do
      tab == "hoje" ? base_scope.registered_on(Date.current) : history_scope
    end
  end

  def in_church_zone(&)
    Time.use_zone(user.church.timezone, &)
  end

  def base_scope
    user.church.welcome_records
  end

  def history_scope
    scope = base_scope
    scope = filter_by_name(scope)
    scope = filter_by_type(scope)
    scope = filter_by_service(scope)
    scope = filter_by_date_range(scope)
    scope = scope.where(became_member: true) if params[:members_only].present?
    scope
  end

  def filter_by_name(scope)
    return scope if params[:q].to_s.strip.blank?

    scope.where("name ILIKE ?", "%#{params[:q].to_s.strip}%")
  end

  def filter_by_type(scope)
    return scope unless WelcomeRecord.visitor_types.key?(params[:type].to_s)

    scope.where(visitor_type: params[:type])
  end

  def filter_by_service(scope)
    return scope unless WelcomeRecord::SERVICES.include?(params[:service])

    scope.where(service: params[:service])
  end

  def filter_by_date_range(scope)
    from = parse_date(params[:start_date])
    to   = parse_date(params[:end_date])
    scope = scope.where(created_at: from.beginning_of_day..) if from
    scope = scope.where(created_at: ..to.end_of_day) if to
    scope
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
