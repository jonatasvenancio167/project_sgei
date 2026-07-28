# frozen_string_literal: true

class MemberchipPolicy < ChurchModulePolicy
  MODULE_KEY = "departments"

  # Sede sees department rosters across all of its congregations; only the
  # secretary (admin) can remove members from a department, and only in
  # their own church.
  def show?    = module_allowed? && within_hierarchy?
  def destroy? = admin? && same_church?

  private

  def record_church_id
    record.departament&.church_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:departament).where(departaments: { church_id: user.allowed_church_ids })
    end
  end
end
