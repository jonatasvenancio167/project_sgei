# frozen_string_literal: true

module Sidebar
  class ProviderComponent < ViewComponent::Base
    def initialize(default_open: true, class_name: "")
      @default_open = default_open
      @class_name = class_name
    end
  end
end
