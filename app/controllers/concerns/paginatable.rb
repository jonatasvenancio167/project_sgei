# frozen_string_literal: true

# Normalizes the ?per param to the sizes offered by Shared::PaginationComponent.
module Paginatable
  extend ActiveSupport::Concern

  private

  def per_page
    per = params[:per].to_i
    Shared::PaginationComponent::PAGE_SIZE_OPTIONS.include?(per) ? per : 10
  end
end
