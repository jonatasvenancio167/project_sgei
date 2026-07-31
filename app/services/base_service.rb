class BaseService
  include Dry::Monads[:result]

  def self.call(...)
    new(...).call
  end
end
