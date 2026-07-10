# frozen_string_literal: true

class UserPolicy < ChurchModulePolicy
  MODULE_KEY = "members"

  def destroy?
    admin? && same_church? && record != user
  end
end
