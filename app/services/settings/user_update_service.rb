module Settings
  class UserUpdateService < BaseService
    def initialize(user:, params:, performed_by:)
      @user, @params, @actor = user, params, performed_by
    end

    def call
      Access::MemberSaveService.call(church: @actor.church, user: @user, params: @params, performed_by: @actor)
    end
  end
end
