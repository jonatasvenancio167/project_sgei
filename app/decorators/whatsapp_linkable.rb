# Shared phone → WhatsApp deep link for decorators of records with a `phone`.
module WhatsappLinkable
  def whatsapp_url
    return if phone.blank?

    digits = phone.gsub(/\D/, "")
    digits = "55#{digits}" if digits.length <= 11 # DDD + número, sem código do país
    "https://wa.me/#{digits}"
  end
end
