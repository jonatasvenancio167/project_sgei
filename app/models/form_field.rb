class FormField < ApplicationRecord
  TYPES = %w[text textarea email phone number date select radio checkbox].freeze

  TYPE_LABELS = {
    "text"     => "Texto curto",
    "textarea" => "Texto longo",
    "email"    => "E-mail",
    "phone"    => "Telefone",
    "number"   => "Número",
    "date"     => "Data",
    "select"   => "Lista suspensa",
    "radio"    => "Múltipla escolha",
    "checkbox" => "Caixas de seleção"
  }.freeze

  TYPE_ICONS = {
    "text"     => "type",
    "textarea" => "align-left",
    "email"    => "at-sign",
    "phone"    => "phone",
    "number"   => "hash",
    "date"     => "calendar",
    "select"   => "chevrons-up-down",
    "radio"    => "circle-dot",
    "checkbox" => "square-check"
  }.freeze

  belongs_to :form
  has_many :form_answers, dependent: :destroy

  validates :label, presence: true
  validates :label_type, inclusion: { in: TYPES }

  default_scope { order(:position) }

  def type_label
    TYPE_LABELS[label_type] || label_type
  end

  def type_icon
    TYPE_ICONS[label_type] || "type"
  end

  def choice_field?
    %w[select radio checkbox].include?(label_type)
  end

  def choices
    return [] unless options.is_a?(Hash)
    Array(options["choices"]).reject(&:blank?)
  end
end
