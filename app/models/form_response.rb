class FormResponse < ApplicationRecord
  belongs_to :form
  belongs_to :user, optional: true
  has_many :form_answers, dependent: :destroy

  validates :token, uniqueness: true, allow_nil: true

  before_create :generate_token

  def submitter_name
    user&.name || guest_name || "Anônimo"
  end

  def submitter_email
    user&.email || guest_email || ""
  end

  def submitted_on
    (submitted_at || created_at).strftime("%d/%m/%Y %H:%M")
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
