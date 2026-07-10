# frozen_string_literal: true

# Headless policy for the calendar screen (module-gated, no backing model).
class CalendarPolicy < ApplicationPolicy
  def index?
    RolePermission.allowed?(church: user.church, role: user.role, module_key: "calendar")
  end
end
