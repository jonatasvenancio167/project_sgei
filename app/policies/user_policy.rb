# frozen_string_literal: true

class UserPolicy < ChurchModulePolicy
  MODULE_KEY = "members"

  # Sede sees members across all of its congregations; editing/removing
  # stays restricted to the user's own church.
  def show? = module_allowed? && within_hierarchy?

  def destroy?
    admin? && same_church? && record != user
  end

  # Convite de Membro: only the secretary approves/rejects a pending
  # self-registration, and only within their own church (docs/Ekklesia/telas/membros.md §3.3).
  def approve? = admin? && same_church? && record.status_pending?
  def reject?  = admin? && same_church? && record.status_pending?

  # Only the secretary (admin) can promote/demote a member's role.
  def update_role?
    admin?
  end

  class Scope < ChurchModulePolicy::Scope
    def resolve
      scope.where(church_id: user.allowed_church_ids)
    end
  end
end
