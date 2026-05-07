class User < ApplicationRecord

  enum status: { active: 0, inactive: 1 }
  enum role: { admin: 0, leader: 1, member: 2 }
end
