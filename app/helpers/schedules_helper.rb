module SchedulesHelper
  MONTHS_PT = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro].freeze
  WDAYS_PT = %w[Dom Seg Ter Qua Qui Sex Sáb].freeze

  def date_label(date)
    return "—" if date.blank?

    "#{date.strftime('%d/%m')} (#{WDAYS_PT[date.wday]})"
  end

  def render_cell_value(column, value, users_map = {})
    return content_tag(:span, "—", class: "text-muted-foreground/50") if value.blank?

    case column.column_type
    when "member"
      users_map[value]&.name || "—"
    when "date"
      Date.parse(value).strftime("%d/%m") rescue value
    when "boolean"
      value == "true" ? "Sim" : "Não"
    else
      value
    end
  end

  def month_label(month)
    date = Date.strptime(month, "%Y-%m")
    "#{MONTHS_PT[date.month - 1]} #{date.year}"
  end

  def previous_month(month)
    (Date.strptime(month, "%Y-%m") << 1).strftime("%Y-%m")
  end

  def next_month(month)
    (Date.strptime(month, "%Y-%m") >> 1).strftime("%Y-%m")
  end
end
