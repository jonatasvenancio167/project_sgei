# frozen_string_literal: true

class EventPolicy < ChurchModulePolicy
  MODULE_KEY = "events"

  # Only the church secretary (admin role) can create or change events.
  def create?
    admin?
  end

  def update?  = admin? && same_church?
  def destroy? = admin? && same_church?
end
