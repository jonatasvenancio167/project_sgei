class Address < ApplicationRecord
  validates :state, length: { maximum: 2 }

  def city_with_state
    [city, state].compact_blank.join("/")
  end

  def summary
    street_line = [street, number].compact_blank.join(", ")
    [street_line.presence, complement, neighborhood, city_with_state.presence].compact.join(" · ")
  end
end
