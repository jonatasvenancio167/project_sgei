# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index?   = true
  def show?    = same_church?
  def create?  = admin?
  def update?  = admin? && same_church?
  def destroy? = admin? && same_church?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(church_id: user.church_id)
    end
  end
end
