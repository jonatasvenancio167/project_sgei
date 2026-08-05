class EventDecorator < BaseDecorator
  # "Sab, 07 Jun · 19h00" (§4.2). start_time é opcional — sem ele, mostra só a data.
  def start_date_formatted
    date_part = I18n.l(object.start_date, format: "%a, %d %b")
    return date_part if object.start_time.blank?

    "#{date_part} · #{I18n.l(object.start_time, format: "%Hh%M")}"
  end

  def visibility_badge_class
    case object.visibility
    when "private_event" then "bg-slate-100 text-slate-700"
    when "member_only" then "bg-blue-100 text-blue-700"
    when "public_event" then "bg-green-100 text-green-700"
    else "bg-secondary text-secondary-foreground"
    end
  end

  # Cores por status (§4.3).
  def status_badge_class
    case object.status
    when "approved"         then "bg-emerald-100 text-emerald-700"
    when "pending_approval" then "bg-amber-100 text-amber-700"
    when "draft"            then "bg-slate-100 text-slate-700"
    when "rejected"         then "bg-red-100 text-red-700"
    when "cancelled"        then "bg-red-200 text-red-900"
    when "archived"         then "bg-slate-200 text-slate-600"
    else "bg-secondary text-secondary-foreground"
    end
  end

  def highlighted_row?
    object.pending_approval?
  end

  def department_name
    object.departament&.name || "Geral"
  end

  # Delega pra EventPolicy — usado pela coluna de Ações (§4.4).
  def can?(action)
    view_context.policy(object).public_send(:"#{action}?")
  end
end
