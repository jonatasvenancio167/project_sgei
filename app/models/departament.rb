class Departament < ApplicationRecord
  COLOR_CHOICES = [
    { key: "bg-red-500 text-white", label: "Vermelho" },
    { key: "bg-blue-500 text-white", label: "Azul" },
    { key: "bg-green-500 text-white", label: "Verde" },
    { key: "bg-yellow-500 text-black", label: "Amarelo" },
    { key: "bg-purple-500 text-white", label: "Roxo" },
    { key: "bg-pink-500 text-white", label: "Rosa" },
    { key: "bg-indigo-500 text-white", label: "Indigo" },
    { key: "bg-emerald-500 text-white", label: "Esmeralda" }
  ].freeze

  ICON_CHOICES = [
    "music",
    "users",
    "heart",
    "hand-heart",
    "baby",
    "book-open",
    "church",
    "sparkles"
  ].freeze

  belongs_to :church
  has_many :events, dependent: :destroy
  has_many :memberchips, dependent: :destroy
  has_many :users, through: :memberchips

  validates :name, presence: true, uniqueness: { scope: :church_id }
  validates :color, presence: true, inclusion: { in: COLOR_CHOICES.map { |c| c[:key] } }
  validates :icon, presence: true, inclusion: { in: ICON_CHOICES }

  def leader
    memberchips.find_by(role: :leader)&.user
  end

  def next_event
    events.where("start_date >= ?", Date.today).order(:start_date).first
  end
end
