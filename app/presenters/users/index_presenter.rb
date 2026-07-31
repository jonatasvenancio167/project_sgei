module Users
  # Groups pagination and listing data for the members index (panel/members)
  # so the controller action stays at a single instance variable.
  class IndexPresenter
    PAGE_SIZES = [10, 25, 50].freeze
    DEFAULT_PAGE_SIZE = 10

    attr_reader :departaments, :per, :page, :total, :total_pages, :users, :new_user

    def initialize(scope:, departaments:, params:)
      @departaments = departaments
      @per = PAGE_SIZES.include?(params[:per].to_i) ? params[:per].to_i : DEFAULT_PAGE_SIZE
      @total = scope.count
      @total_pages = [(@total.to_f / @per).ceil, 1].max
      @page = [[params[:page].to_i, 1].max, @total_pages].min
      @users = scope.offset((@page - 1) * @per).limit(@per)
      @new_user = User.new
    end
  end
end
