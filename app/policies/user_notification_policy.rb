# frozen_string_literal: true

class UserNotificationPolicy < ApplicationPolicy
  def index?   = true
  def show?    = own?
  def create?  = user.can_access?("settings", action: "manage")
  def update?  = own?
  def destroy? = own?

  private

  def own?
    record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
