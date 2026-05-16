# frozen_string_literal: true

module Shared
  class ModalComponent < ViewComponent::Base
    renders_one :header
    renders_one :footer
    renders_one :body

    def initialize(id:, title: nil, description: nil, size: :md)
      @id = id
      @title = title
      @description = description
      @size = size
    end

    private

    attr_reader :id, :title, :description, :size

    def modal_classes
      case size
      when :sm then "sm:max-w-md"
      when :lg then "sm:max-w-2xl"
      when :xl then "sm:max-w-4xl"
      else "sm:max-w-lg"
      end
    end
  end
end
