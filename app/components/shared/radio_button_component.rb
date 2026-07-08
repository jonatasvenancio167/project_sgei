# frozen_string_literal: true

module Shared
  # Styled radio button rendered as a selectable "pill", with optional lucide icon.
  #
  #   <%= render Shared::RadioButtonComponent.new(
  #         name: "notification_settings[event_created][channel]",
  #         value: "email",
  #         label: "Email",
  #         icon: "mail",
  #         checked: true
  #       ) %>
  class RadioButtonComponent < ViewComponent::Base
    include LucideHelper

    def initialize(name:, value:, label:, icon: nil, checked: false, disabled: false, required: false)
      @name = name
      @value = value
      @label = label
      @icon = icon
      @checked = checked
      @disabled = disabled
      @required = required
    end

    private

    attr_reader :name, :value, :label, :icon, :checked, :disabled, :required

    def input_id
      "#{name}_#{value}".parameterize(separator: "_")
    end
  end
end
