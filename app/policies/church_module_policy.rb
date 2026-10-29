class ChurchModulePolicy < ApplicationPolicy
  MODULE_KEY = nil
  def index? = permitted?("read")
  def show? = permitted?("read", record)
  def create? = permitted?("manage", record)
  def update? = permitted?("manage", record)
  def destroy? = permitted?("manage", record)

  private

  def permitted?(action, resource = nil)
    user.can_access?(self.class::MODULE_KEY, action: action, record: resource)
  end

  def module_allowed? = permitted?("read")

  class Scope < ApplicationPolicy::Scope
    def resolve
      relation = scope.all
      policy_class = "#{relation.klass.name}Policy".constantize
      Access::ScopeQuery.new(user: user, scope: relation, module_key: policy_class::MODULE_KEY).call
    end
  end
end
