# frozen_string_literal: true

# Headless policy for the calendar screen (module-gated, no backing model).
class CalendarPolicy < ApplicationPolicy
  def index?
    RolePermissions::AllowedQuery.new(church: user.church, role: user.role, module_key: "calendar").call
  end
end
