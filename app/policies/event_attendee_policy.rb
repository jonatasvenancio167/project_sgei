# frozen_string_literal: true

class EventAttendeePolicy < ChurchModulePolicy
  MODULE_KEY = "events"

  private

  def record_church_id
    record.event&.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:event).where(events: { church_id: user.church_id })
    end
  end
end
