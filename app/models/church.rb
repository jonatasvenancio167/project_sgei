class Church < ApplicationRecord
  TIMEZONES = {
    "America/Noronha"     => "Fernando de Noronha (GMT-2)",
    "America/Fortaleza"   => "Fortaleza / Brasília (GMT-3)",
    "America/Sao_Paulo"   => "São Paulo (GMT-3)",
    "America/Manaus"      => "Manaus (GMT-4)",
    "America/Rio_Branco"  => "Rio Branco (GMT-5)"
  }.freeze

  PRIMARY_COLORS = %w[#4f6e5d #2f5233 #1d4ed8 #7c3aed #b45309 #be123c].freeze

  CHURCH_TYPE_LABELS = {
    "headquarters"    => "Sede",
    "congregation"    => "Congregação",
    "preaching_point" => "Ponto de Pregação"
  }.freeze

  has_one_attached :logo

  belongs_to :address, optional: true, dependent: :destroy
  belongs_to :parent_church, class_name: "Church", optional: true
  has_many :congregations, class_name: "Church", foreign_key: :parent_church_id,
                           inverse_of: :parent_church, dependent: :nullify

  has_many :departaments, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :forms, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :role_permissions, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :welcome_records, dependent: :destroy

  enum :church_type, { headquarters: 0, congregation: 1, preaching_point: 2 }, prefix: :type
  enum :status, { active: 0, inactive: 1 }, prefix: true

  accepts_nested_attributes_for :address, update_only: true, reject_if: :all_blank

  validates :name, presence: true
  validates :cnpj, cnpj: true

  delegate :city_with_state, to: :address, allow_nil: true

  def display_name_or_default
    display_name.presence || name
  end

  def church_type_label
    CHURCH_TYPE_LABELS[church_type]
  end

  # Generates a URL-safe, unique slug from a name, appending a random
  # suffix on collision (used for self-service church creation).
  def self.generate_unique_slug(name)
    base = name.to_s.parameterize.presence || "igreja"
    slug = base
    slug = "#{base}-#{SecureRandom.hex(2)}" while Church.exists?(slug: slug)
    slug
  end

  def sede?
    parent_church_id.nil?
  end

  # IDs visible to this church for hierarchy-aware modules (Membros,
  # Departamentos, Formulários, Aniversariantes): the Sede sees itself and
  # every descendant congregation; any other unit sees only itself.
  def accessible_church_ids
    return [id] unless sede?

    [id] + congregations.flat_map(&:accessible_church_ids)
  end

end
