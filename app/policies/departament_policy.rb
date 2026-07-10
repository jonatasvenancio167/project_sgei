# frozen_string_literal: true

class DepartamentPolicy < ChurchModulePolicy
  MODULE_KEY = "departments"

  # Only the secretary (admin) manages departments themselves.
  def create?  = admin?
  def update?  = admin? && same_church?
  def destroy? = admin? && same_church?

  # Leaders can add members to the departments they belong to.
  def add_members?
    return false unless same_church?

    admin? || (leader? && user.departament_ids.include?(record.id))
  end
end
