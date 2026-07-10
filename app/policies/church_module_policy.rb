# frozen_string_literal: true

# Base policy for resources gated by the per-module permission matrix
# (RolePermission, managed in Configurações → Perfis e Permissões).
#
# Rules:
#   - Records are only visible within the user's church (tenant isolation).
#   - Viewing requires the module to be allowed for the user's role.
#   - Writing requires admin, or leader with the module allowed.
class ChurchModulePolicy < ApplicationPolicy
  MODULE_KEY = nil

  def index?   = module_allowed?
  def show?    = module_allowed? && same_church?
  def create?  = manage?
  def update?  = manage? && same_church?
  def destroy? = manage? && same_church?

  private

  def module_key
    self.class::MODULE_KEY
  end

  def module_allowed?
    RolePermission.allowed?(church: user.church, role: user.role, module_key: module_key)
  end

  def manage?
    admin? || (leader? && module_allowed?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(church_id: user.church_id)
    end
  end
end
