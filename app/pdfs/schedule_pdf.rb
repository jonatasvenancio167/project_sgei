# frozen_string_literal: true

require "prawn"
require "prawn/table"

# Renders a schedule month grid as a downloadable PDF, mirroring the
# panel/schedules/:id/:month table (Data + dynamic columns).
class SchedulePdf
  HEADER_BG = "F3F1EA" # sand tone used by the app's secondary surfaces
  BORDER    = "DDD8CC"
  MUTED     = "6B6B60"

  def initialize(schedule:, month:, columns:, entries:, users_map:)
    @schedule = schedule
    @month    = month
    @columns  = columns
    @entries  = entries
    @users_map = users_map
  end

  def render
    pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 40)

    pdf.text @schedule.name, size: 20, style: :bold
    pdf.move_down 4
    pdf.text "Departamento · #{@schedule.departament&.name} — #{month_label}", size: 11, color: MUTED
    pdf.move_down 18

    if @entries.any?
      pdf.table(table_data, header: true, width: pdf.bounds.width,
                cell_style: { size: 9, padding: [6, 8], border_color: BORDER, border_width: 0.5 }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = HEADER_BG
        t.row(0).text_color = "44443C"
      end
    else
      pdf.text "Nenhuma entrada neste mês.", size: 10, color: MUTED
    end

    pdf.move_down 16
    pdf.text "Gerado em #{Time.current.strftime('%d/%m/%Y %H:%M')}", size: 8, color: MUTED
    pdf.render
  end

  def filename
    "escala-#{@schedule.name.parameterize}-#{@month}.pdf"
  end

  private

  def table_data
    header = ["Data"] + @columns.map { |c| c.name.to_s.upcase_first }
    rows = @entries.map do |entry|
      [date_label(entry.date)] + @columns.map { |c| cell_text(c, entry.cell_values[c.id.to_s]) }
    end
    [header] + rows
  end

  def cell_text(column, value)
    return "—" if value.blank?

    case column.column_type
    when "member"
      @users_map[value]&.name || "—"
    when "date"
      Date.parse(value).strftime("%d/%m") rescue value
    when "boolean"
      value == "true" ? "Sim" : "Não"
    else
      value.to_s
    end
  end

  def date_label(date)
    return "—" if date.blank?

    "#{date.strftime('%d/%m')} (#{SchedulesHelper::WDAYS_PT[date.wday]})"
  end

  def month_label
    date = Date.strptime(@month, "%Y-%m")
    "#{SchedulesHelper::MONTHS_PT[date.month - 1]} #{date.year}"
  end
end
