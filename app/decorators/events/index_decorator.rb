module Events
  class IndexDecorator < BaseDecorator
    attr_reader :q, :params, :user, :events

    def initialize(q, events, params, user, view_context)
      super(q, view_context)
      @q = q
      @events = events
      @params = params
      @user = user
    end

    def period_options
      [
        ["todos", "Todos"],
        ["hoje", "Hoje"],
        ["semana", "Próximos 7 dias"],
        ["mes", "Próximos 30 dias"]
      ]
    end

    def period_class(value)
      active = (params[:period] || "todos") == value
      base = "rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors"
      active ? "#{base} bg-primary text-primary-foreground" : "#{base} bg-secondary text-secondary-foreground hover:bg-secondary/80"
    end

    def has_active_filters?
      (params[:period].present? && params[:period] != "todos") || 
      (params[:q].present? && params[:q].to_unsafe_h.values.any?(&:present?))
    end

    def search_query
      q.title_or_location_or_description_cont
    end

    def period_label
      { "hoje" => "Hoje", "semana" => "Próximos 7 dias", "mes" => "Próximos 30 dias" }[params[:period]]
    end

    def department_label
      return nil unless q.departament_id_eq.present?
      Departament.find_by(id: q.departament_id_eq)&.name || "Geral"
    end

    def visibility_label
      return nil unless q.visibility_eq.present?
      { "0" => "Privada", "1" => "Membros", "2" => "Pública" }[q.visibility_eq.to_s]
    end

    def decorated_events
      events.map { |e| EventDecorator.new(e, view_context) }
    end

    def result_count_text
      count = q.result.count
      "#{count} #{count == 1 ? 'evento encontrado' : 'eventos encontrados'}"
    end


    def department_options
      options = [["Todos os departamentos", ""]]
      depts = user.admin? ? Departament.all : user.departaments + [nil]
      options + depts.map { |d| [d&.name || "Geral", d&.id] }
    end

    def visibility_options
      [["Todas as visibilidades", ""], ["Privada", 0], ["Membros", 1], ["Pública", 2]]
    end

    def sort_options
      [
        ["Data", "start_date asc"],
        ["Data (Desc)", "start_date desc"],
        ["Título", "title asc"],
        ["Título (Desc)", "title desc"],
        ["Inscritos", "event_attendees_count asc"],
        ["Inscritos (Desc)", "event_attendees_count desc"]
      ]
    end
  end
end
