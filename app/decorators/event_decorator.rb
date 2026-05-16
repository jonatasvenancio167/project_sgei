class EventDecorator < BaseDecorator
  def start_date_formatted
    I18n.l(object.start_date, format: "%d/%m %H:%M")
  end

  def visibility_badge_class
    case object.visibility
    when "private_event" then "bg-slate-100 text-slate-700"
    when "member_only" then "bg-blue-100 text-blue-700"
    when "public_event" then "bg-green-100 text-green-700"
    else "bg-secondary text-secondary-foreground"
    end
  end

  def department_name
    object.departament&.name || "Geral"
  end
end
