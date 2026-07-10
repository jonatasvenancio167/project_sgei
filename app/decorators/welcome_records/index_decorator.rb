module WelcomeRecords
  class IndexDecorator < BaseDecorator
    attr_reader :records, :summary, :params, :user

    TAB_OPTIONS = [
      [ "hoje", "Hoje" ],
      [ "historico", "Histórico" ]
    ].freeze

    def initialize(records, summary, params, user, view_context, total_count: nil)
      super(records, view_context)
      @records = records
      @summary = summary
      @params = params
      @user = user
      @total_count = total_count
    end

    def tab
      TAB_OPTIONS.map(&:first).include?(params[:tab]) ? params[:tab] : "hoje"
    end

    def tab_options
      TAB_OPTIONS
    end

    def tab_class(value)
      base = "rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors"
      if tab == value
        "#{base} bg-primary text-primary-foreground"
      else
        "#{base} bg-secondary text-secondary-foreground hover:bg-secondary/80"
      end
    end

    def decorated_records
      @decorated_records ||= records.map do |r|
        RecordDecorator.new(r, view_context, timezone: user.church.timezone)
      end
    end

    # "3 pessoas registradas hoje — 2 visitantes, 1 irmão"
    def today_summary_text
      total = summary[:total]
      people = total == 1 ? "pessoa registrada hoje" : "pessoas registradas hoje"
      "#{total} #{people} — #{visitors_text}, #{brothers_text}"
    end

    # "12 registros · 8 visitantes · 4 irmãos"
    def history_summary_text
      total = summary[:total]
      "#{total} #{total == 1 ? 'registro' : 'registros'} · #{visitors_text} · #{brothers_text}"
    end

    def type_options
      [ [ "Todos os tipos", "todos" ], [ "Visitantes", "visitor" ], [ "Irmãos", "brother" ] ]
    end

    def service_options
      [ [ "Todos os cultos", "todos" ] ] + service_form_options
    end

    def service_form_options
      WelcomeRecord::SERVICES.map { |s| [ s, s ] }
    end

    def now_label
      Time.current.in_time_zone(user.church.timezone).strftime("%d/%m/%Y %H:%M")
    end

    def current_query      = params[:q].to_s
    def current_type       = params[:type].presence || "todos"
    def current_service    = params[:service].presence || "todos"
    def current_start_date = params[:start_date].to_s
    def current_end_date   = params[:end_date].to_s
    def members_only?      = params[:members_only].present?

    def has_active_filters?
      current_query.present? || current_type != "todos" || current_service != "todos" ||
        current_start_date.present? || current_end_date.present? || members_only?
    end

    private

    def visitors_text
      count = summary[:visitors]
      "#{count} #{count == 1 ? 'visitante' : 'visitantes'}"
    end

    def brothers_text
      count = summary[:brothers]
      "#{count} #{count == 1 ? 'irmão' : 'irmãos'}"
    end
  end
end
