# frozen_string_literal: true

class CardComponent < ViewComponent::Base
  renders_one :header
  renders_one :title
  renders_one :description
  renders_one :footer

  def initialize(classes: "")
    @classes = classes
  end

  private

  attr_reader :classes
end
