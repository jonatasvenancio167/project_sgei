module Birthdays
  class IndexDecorator < BaseDecorator
    attr_reader :users, :summary, :params, :user

    PERIOD_OPTIONS = [
      [ "semana", "Esta semana" ],
      [ "mes", "Este mês" ]
    ].freeze

    MONTH_WEEK_GROUPS = [
      [ "Semana 1 (1–7)",    1..7 ],
      [ "Semana 2 (8–14)",   8..14 ],
      [ "Semana 3 (15–21)", 15..21 ],
      [ "Semana 4+ (22–31)", 22..31 ]
    ].freeze

    def initialize(users, summary, params, user, view_context, total_count: nil)
      super(users, view_context)
      @users = users
      @summary = summary
      @params = params
      @user = user
      @total_count = total_count
    end

    def period
      PERIOD_OPTIONS.map(&:first).include?(params[:period]) ? params[:period] : "semana"
    end

    def period_options
      PERIOD_OPTIONS
    end

    def period_class(value)
      base = "rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors"
      if period == value
        "#{base} bg-primary text-primary-foreground"
      else
        "#{base} bg-secondary text-secondary-foreground hover:bg-secondary/80"
      end
    end

    def department_options
      [ [ "Todos os departamentos", "todos" ] ] +
        user.church.departaments.order(:name).map { |d| [ d.name, d.id.to_s ] }
    end

    def current_dept
      params[:dept].presence || "todos"
    end

    def decorated_users
      @decorated_users ||= users.map { |u| UserDecorator.new(u, view_context) }
    end

    # "Este mês" grouped by week of the month, keeping only non-empty groups.
    def month_groups
      MONTH_WEEK_GROUPS.filter_map do |label, day_range|
        group = decorated_users.select { |u| day_range.cover?(u.birth_date.day) }
        [ label, group ] if group.any?
      end
    end

    def today_count = summary[:today]
    def week_count  = summary[:week]
    def month_count = summary[:month]

    def empty_message
      if period == "semana"
        "Ninguém faz aniversário nos próximos 7 dias."
      else
        "Nenhum aniversariante neste mês."
      end
    end

    def result_count_text
      count = @total_count || users.size
      "#{count} #{count == 1 ? 'aniversariante' : 'aniversariantes'}"
    end
  end
end
