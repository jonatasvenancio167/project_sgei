# Tenant isolation guard: every domain model tied to a church must declare
# the association and can never be persisted without it, regardless of
# `optional:` slipping into a future `belongs_to` change or mass-assignment.
module BaseEntity
  extend ActiveSupport::Concern

  included do
    belongs_to :church
    validates :church_id, presence: true
  end
end
