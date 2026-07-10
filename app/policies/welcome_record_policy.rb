# frozen_string_literal: true

class WelcomeRecordPolicy < ChurchModulePolicy
  MODULE_KEY = "welcome"

  def toggle_member?
    update?
  end
end
