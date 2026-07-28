# frozen_string_literal: true

class UserPolicy < ChurchModulePolicy
  MODULE_KEY = "members"

  # Sede sees members across all of its congregations; editing/removing
  # stays restricted to the user's own church.
  def show? = module_allowed? && within_hierarchy?

  def destroy?
    admin? && same_church? && record != user
  end

  class Scope < ChurchModulePolicy::Scope
    def resolve
      scope.where(church_id: user.allowed_church_ids)
    end
  end
end
