module Birthdays
  class UserDecorator < BaseDecorator
    include WhatsappLinkable

    AVATAR_COLORS = %w[bg-secondary bg-chart-2/30 bg-chart-3/30 bg-chart-4/30 bg-chart-5/30].freeze

    MONTH_NAMES_PT = %w[
      janeiro fevereiro março abril maio junho
      julho agosto setembro outubro novembro dezembro
    ].freeze

    def initials
      name.to_s.split.first(2).map { |part| part[0]&.upcase }.join
    end

    def avatar_color
      AVATAR_COLORS[id % AVATAR_COLORS.size]
    end

    # "15 de julho · hoje 🎉" / "· amanhã" / "· em 5 dias"
    def birthday_label
      date_part = "#{birth_date.day} de #{MONTH_NAMES_PT[birth_date.month - 1]}"
      relative = relative_label
      relative ? "#{date_part} · #{relative}" : date_part
    end

    def department_name
      primary_department_name
    end

    private

    def relative_label
      case days_until_birthday
      when 0 then "hoje 🎉"
      when 1 then "amanhã"
      when 2..7 then "em #{days_until_birthday} dias"
      end
    end
  end
end
