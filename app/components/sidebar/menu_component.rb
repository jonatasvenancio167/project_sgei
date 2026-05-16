# frozen_string_literal: true

module Sidebar
  class MenuComponent < ViewComponent::Base
    def initialize(class_name: "")
      @class_name = class_name
    end

    private

    attr_reader :class_name
  end
end
