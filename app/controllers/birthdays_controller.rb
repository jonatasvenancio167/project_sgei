class BirthdaysController < ApplicationController
  include Paginatable

  # GET /painel/aniversariantes
  def index
    authorize :birthday, :index?

    query = BirthdayQuery.new(params, user: current_user)
    @pagy, @birthday_users = pagy(query.call, limit: per_page)
    @decorator = ::Birthdays::IndexDecorator.new(
      @birthday_users, query.summary, params, current_user, view_context, total_count: @pagy.count
    )
  end
end
