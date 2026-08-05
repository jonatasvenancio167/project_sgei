module Registrations
  # Onboarding: creates a new Church (tenant) and its first User (admin) in
  # a single transaction. Used by the public sign-up wizard at /users/sign_up.
  class SignUpService < BaseService
    def initialize(user_params:, church_params:, terms_accepted:)
      @user_params = user_params
      @church_params = church_params
      @terms_accepted = terms_accepted
    end

    def call
      return Failure(:terms_not_accepted) unless terms_accepted

      church = Church.new(church_params)
      church.slug = Church.generate_unique_slug(church.name)
      church.church_type = "headquarters" if church.church_type.blank?

      user = nil

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless church.save

        user = church.users.build(user_params)
        user.role = :admin
        user.status = :active
        raise ActiveRecord::Rollback unless user.save
      end

      return Failure(church) if church.errors.any?
      return Failure(user) if user.errors.any?

      Audit::RecordService.call(
        church: church, user: user,
        module_key: "users", action: "Cadastro via onboarding", detail: church.name
      )

      Success(user)
    end

    private

    attr_reader :user_params, :church_params, :terms_accepted
  end
end
