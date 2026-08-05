class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  include BaseEntity

  belongs_to :address, optional: true, dependent: :destroy
  accepts_nested_attributes_for :address, reject_if: :all_blank
  has_many :memberchips, dependent: :destroy
  has_many :departaments, through: :memberchips
  has_many :event_attendees, dependent: :destroy
  has_many :events, through: :event_attendees
  has_many :schedule_assignments, dependent: :destroy
  has_many :schedule_entries, through: :schedule_assignments
  has_many :audit_logs, dependent: :nullify

  enum :status, { active: 0, inactive: 1 }, prefix: true
  enum :role, { admin: 0, leader: 1, member: 2, pastor: 3, co_pastor: 4 }

  # ── Validations ──────────────────────────────────────────────────────────
  validates :name, presence: true
  validates :phone, presence: true,
                    format: { with: /\A\(\d{2}\) \d{4,5}-\d{4}\z/ },
                    allow_blank: false

  # ── Birthday scopes ──────────────────────────────────────────────────────
  # Recurring-date scopes (month/day, ignoring year). All scopes hit the
  # expression index on (EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date)).
  BIRTH_MONTH_DAY_SQL = "(EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date))"

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

  # Make email optional (Devise requires email by default; override here)
  def email_required?
    false
  end

  def password_required?
    encrypted_password.blank? ? new_record? : false
  end

  def role_label
    case role
    when "admin" then "Secretaria"
    when "leader" then "Líder de Departamento"
    when "member" then "Membro"
    when "pastor" then "Pastor"
    when "co_pastor" then "Copastor"
    else role&.capitalize
    end
  end

  def allowed_church_ids
    church.accessible_church_ids
  end

  def primary_department
    departaments.first
  end

  def primary_department_name
    primary_department&.name || "Geral"
  end

  def can_see_dept?(dept)
    return true if admin?
    return true if dept.blank? || dept == "Geral"

    departaments.pluck(:name).include?(dept)
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
