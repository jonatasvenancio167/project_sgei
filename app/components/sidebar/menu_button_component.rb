# frozen_string_literal: true

module Sidebar
  class MenuButtonComponent < ViewComponent::Base
    def initialize(variant: :default, size: :default, is_active: false, tooltip: nil, class_name: "", href: nil)
      @variant = variant
      @size = size
      @is_active = is_active
      @tooltip = tooltip
      @class_name = class_name
      @href = href
    end

    private

    attr_reader :variant, :size, :is_active, :tooltip, :class_name, :href

    def button_classes
      [
        "peer/menu-button flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors outline-none ring-sidebar-ring focus-visible:ring-2 disabled:pointer-events-none disabled:opacity-50",
        active_classes,
        class_name
      ].compact.join(" ")
    end

    def active_classes
      if is_active
        "bg-sidebar-accent text-sidebar-accent-foreground font-medium"
      else
        "text-muted-foreground hover:bg-sidebar-accent/60 hover:text-foreground"
      end
    end
  end
end
