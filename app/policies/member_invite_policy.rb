# frozen_string_literal: true

# Convite de Membro is restricted to the secretary (admin) and the pastor —
# unlike the rest of the Membros module, it is never opened to leaders via
# the RolePermission matrix (docs/Ekklesia/telas/membros.md §7.2).
class MemberInvitePolicy < ApplicationPolicy
  def index?   = can_manage?
  def create?  = can_manage?
  def destroy? = can_manage? && same_church?

  private

  def can_manage?
    admin? || pastor?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(church_id: user.church_id)
    end
  end
end
