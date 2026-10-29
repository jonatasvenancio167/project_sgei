# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index?   = true
  def show?    = same_church?
  def create?  = user.can_access?("settings", action: "manage")
  def update?  = user.can_access?("settings", action: "manage") && same_church?
  def destroy? = user.can_access?("settings", action: "manage") && same_church?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(church_id: user.church_id)
    end
  end
end
