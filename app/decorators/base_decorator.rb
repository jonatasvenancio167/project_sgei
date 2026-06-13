class BaseDecorator
  include ActionView::Helpers
  include Rails.application.routes.url_helpers

  def initialize(object, view_context)
    @object = object
    @view_context = view_context
  end

  private

  attr_reader :object, :view_context

  def method_missing(method, *args, &block)
    @object.send(method, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    @object.respond_to?(method, include_private) || super
  end
end
