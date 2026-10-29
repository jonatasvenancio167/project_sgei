class AccessProfilePolicy < ApplicationPolicy
  def index? = user.can_access?("access", action: "manage")
  def create? = index?
  def update? = index? && same_church?
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.can_access?("access", action: "manage") ? scope.where(church_id: user.church_id) : scope.none
    end
  end
end
