# frozen_string_literal: true

module Shared
  class PaginationComponent < ViewComponent::Base
    attr_reader :current_page, :total_pages, :total_count, :page_size, :item_label, :url_builder

    # @param current_page [Integer]
    # @param total_pages  [Integer]
    # @param total_count  [Integer]
    # @param page_size    [Integer] current per-page value
    # @param item_label   [Hash]   { singular: "membro", plural: "membros" }
    # @param url_builder  [Proc]   receives (page:, per:) and returns a URL string
    def initialize(current_page:, total_pages:, total_count:, page_size:, url_builder:, item_label: {})
      @current_page = current_page
      @total_pages  = total_pages
      @total_count  = total_count
      @page_size    = page_size
      @url_builder  = url_builder
      @item_label   = { singular: "item", plural: "itens" }.merge(item_label)
    end

    def page_label
      current_page == 1 ? item_label[:singular] : item_label[:plural]
    end

    # Visible range of items on current page
    def range_start
      [(current_page - 1) * page_size + 1, total_count].min
    end

    def range_end
      [current_page * page_size, total_count].min
    end

    # Build an array of page numbers and :gap symbols for pagination display.
    # Example for 10 pages, current = 5: [1, :gap, 4, 5, 6, :gap, 10]
    def page_windows
      return (1..total_pages).to_a if total_pages <= 7

      pages = []
      pages << 1

      if current_page > 4
        pages << :gap
      elsif current_page > 2
        pages << 2
        pages << 3
      else
        pages << 2
      end

      window = ((current_page - 1)..(current_page + 1)).select { |p| p > 2 && p < total_pages }
      pages.concat(window)

      if current_page < total_pages - 3
        pages << :gap
      elsif current_page < total_pages - 1
        pages << (total_pages - 1)
      end

      pages << total_pages
      pages.uniq
    end

    PAGE_SIZE_OPTIONS = [10, 25, 50].freeze
  end
end
