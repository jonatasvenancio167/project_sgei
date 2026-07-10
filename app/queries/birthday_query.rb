# Members of the user's church with birthdays in the selected period.
# The department filter runs as a subquery on memberchips; department data
# for display is preloaded separately to avoid a heavy join on the result set.
class BirthdayQuery
  PERIODS = %w[semana mes].freeze
  WEEK_WINDOW_DAYS = 6 # today + 6 = "próximos 7 dias"

  def initialize(params = {}, user:)
    @params = params
    @user = user
  end

  def call
    apply_ordering(apply_period(base_scope)).includes(:departaments)
  end

  def period
    PERIODS.include?(params[:period]) ? params[:period] : PERIODS.first
  end

  # One indexed count per summary card.
  def summary
    {
      today: base_scope.birthday_between(Date.current, Date.current).count,
      week:  base_scope.birthday_between(Date.current, week_window_end).count,
      month: base_scope.birthday_in_month(Date.current.month).count
    }
  end

  private

  attr_reader :params, :user

  # Every member sees the whole church's birthdays; access is module-gated.
  def base_scope
    filter_by_departament(user.church.users.status_active.with_birth_date)
  end

  # Subquery instead of join: no duplicate rows (so no DISTINCT, which would
  # conflict with the birthday ORDER BY expressions on Postgres).
  def filter_by_departament(scope)
    return scope if params[:dept].blank? || params[:dept] == "todos"

    scope.where(id: Memberchip.where(departament_id: params[:dept]).select(:user_id))
  end

  def apply_period(scope)
    if period == "semana"
      scope.birthday_between(Date.current, week_window_end)
    else
      scope.birthday_in_month(Date.current.month)
    end
  end

  def apply_ordering(scope)
    period == "semana" ? scope.order_by_upcoming_birthday : scope.order_by_birth_day
  end

  def week_window_end
    WEEK_WINDOW_DAYS.days.from_now.to_date
  end
end
