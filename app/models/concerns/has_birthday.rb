# frozen_string_literal: true

# Birthday domain logic: recurring-date scopes (month/day, ignoring year)
# and next-occurrence calculations. All scopes hit the expression index
# on (EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date)).
module HasBirthday
  extend ActiveSupport::Concern

  BIRTH_MONTH_DAY_SQL = "(EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date))"

  included do
    scope :with_birth_date, -> { where.not(birth_date: nil) }

    scope :birthday_in_month, lambda { |month|
      with_birth_date.where("EXTRACT(MONTH FROM birth_date) = ?", month)
    }

    # Birthdays whose month/day falls inside the date window (year-agnostic),
    # including windows that cross a month or year boundary.
    scope :birthday_between, lambda { |start_date, end_date|
      pairs = (start_date..end_date).map { |d| [ d.month, d.day ] }.uniq
      placeholders = ([ "(?, ?)" ] * pairs.size).join(", ")
      with_birth_date.where("#{BIRTH_MONTH_DAY_SQL} IN (#{placeholders})", *pairs.flatten)
    }

    # Closest upcoming birthday first, wrapping the year
    # (e.g. on Dec 30, Jan 2 sorts after Dec 31).
    scope :order_by_upcoming_birthday, lambda { |from = Date.current|
      month_day = "(EXTRACT(MONTH FROM birth_date) * 100 + EXTRACT(DAY FROM birth_date))"
      pivot = from.month * 100 + from.day
      order(Arel.sql(
        "CASE WHEN #{month_day} >= #{pivot} THEN #{month_day} ELSE #{month_day} + 1231 END ASC"
      ), :name)
    }

    scope :order_by_birth_day, -> { order(Arel.sql("EXTRACT(DAY FROM birth_date) ASC"), :name) }
  end

  def birthday_today?(today = Date.current)
    birth_date.present? && birth_date.month == today.month && birth_date.day == today.day
  end

  def next_birthday(from = Date.current)
    return if birth_date.blank?

    candidate = birthday_in_year(from.year)
    candidate >= from ? candidate : birthday_in_year(from.year + 1)
  end

  def days_until_birthday(from = Date.current)
    return if birth_date.blank?

    (next_birthday(from) - from).to_i
  end

  private

  def birthday_in_year(year)
    Date.new(year, birth_date.month, birth_date.day)
  rescue Date::Error
    Date.new(year, 3, 1) # Feb 29 in non-leap years
  end
end
