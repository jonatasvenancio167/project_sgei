class ScheduleDecorator < BaseDecorator
  def department_name
    object.departament.name
  end

  def column_names
    object.schedule_columns.map(&:name)
  end

  def columns_count
    object.schedule_columns.size
  end

  def columns_count_label
    count = columns_count
    "#{count} coluna#{"s" unless count == 1}"
  end

  def columns_preview
    names = column_names
    preview = names.first(3).join(", ")
    preview += "…" if names.size > 3
    preview
  end

  def current_month
    Date.current.strftime("%Y-%m")
  end

  def month_path
    panel_schedule_month_path(object, month: current_month)
  end

  def color_bar_class
    object.color.split.first
  end
end
