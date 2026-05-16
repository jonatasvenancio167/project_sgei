# frozen_string_literal: true

module Sidebar
  class SidebarComponent < ViewComponent::Base
    def initialize(side: :left, variant: :sidebar, collapsible: :offcanvas, class_name: "")
      @side = side
      @variant = variant
      @collapsible = collapsible
      @class_name = class_name
    end
  end
end
