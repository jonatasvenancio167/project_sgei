module WelcomeRecords
  class RecordDecorator < BaseDecorator
    include WhatsappLinkable

    def initialize(record, view_context, timezone:)
      super(record, view_context)
      @timezone = timezone
    end

    def type_badge_class
      base = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium text-foreground"
      visitor_type_visitor? ? "#{base} bg-chart-3/25" : "#{base} bg-chart-2/30"
    end

    def registered_at_label
      local_created_at.strftime("%d/%m/%Y %H:%M")
    end

    def time_label
      local_created_at.strftime("%H:%M")
    end

    # "Igreja da Paz · Maracanaú" (only the parts that were filled in)
    def origin_line
      [ congregation, city ].map(&:presence).compact.join(" · ")
    end

    private

    def local_created_at
      created_at.in_time_zone(@timezone)
    end
  end
end
