# frozen_string_literal: true

class MemberchipPolicy < ChurchModulePolicy
  MODULE_KEY = "departments"

  # Only the secretary (admin) can remove members from a department;
  # leaders may only add and view.
  def destroy? = admin? && same_church?

  private

  def record_church_id
    record.departament&.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:departament).where(departaments: { church_id: user.church_id })
    end
  end
end
