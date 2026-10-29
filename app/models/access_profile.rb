class AccessProfile < ApplicationRecord
  include BaseEntity
  belongs_to :parent_profile, class_name: "AccessProfile", optional: true
  has_many :role_permissions, dependent: :destroy
  has_many :profile_assignments, dependent: :restrict_with_error

  before_validation :normalize_name
  validates :key, :name, :description, :normalized_name, presence: true
  validates :key, :normalized_name, uniqueness: { scope: :church_id }
  validate :valid_parent
  validate :stable_identity, on: :update
  before_destroy { throw(:abort) if standard? }

  def self.normalize(value)
    I18n.transliterate(value.to_s).downcase.strip.gsub(/\s+/, " ")
  end

  def permission(module_key, action_key)
    local = if role_permissions.loaded?
      role_permissions.detect { |permission| permission.module_key == module_key && permission.action_key == action_key }
    else
      role_permissions.find_by(module_key: module_key, action_key: action_key)
    end
    local || parent_profile&.permission(module_key, action_key)
  end

  private

  def normalize_name
    self.normalized_name = self.class.normalize(name)
  end

  def valid_parent
    return unless parent_profile
    errors.add(:parent_profile, :invalid) unless parent_profile.church_id == church_id && parent_profile.key == "member" && key != "member"
  end

  def stable_identity
    errors.add(:key, "não pode ser alterado") if will_save_change_to_key?
    errors.add(:standard, "não pode ser alterado") if will_save_change_to_standard?
  end
end
