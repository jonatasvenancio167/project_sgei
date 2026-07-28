# frozen_string_literal: true

class DepartamentPolicy < ChurchModulePolicy
  MODULE_KEY = "departments"

  # Sede sees departments across all of its congregations; only the
  # secretary (admin) manages departments, and only within their own church.
  def show?    = module_allowed? && within_hierarchy?
  def create?  = admin?
  def update?  = admin? && same_church?
  def destroy? = admin? && same_church?

  # Leaders can add members to the departments they belong to.
  def add_members?
    return false unless same_church?

    admin? || (leader? && user.departament_ids.include?(record.id))
  end

  class Scope < ChurchModulePolicy::Scope
    def resolve
      scope.where(church_id: user.allowed_church_ids)
    end
  end
end
