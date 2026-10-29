module Settings
  class UserInviteService < BaseService
    def initialize(church:, params:, performed_by:)
      @church, @params, @actor = church, params, performed_by
    end

    def call
      Access::MemberSaveService.call(church: @church, params: @params, performed_by: @actor)
    end
  end
end
