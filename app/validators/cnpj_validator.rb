# Validates the format "00.000.000/0000-00" and the CNPJ check digits.
class CnpjValidator < ActiveModel::EachValidator
  FORMAT = /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    unless value.match?(FORMAT)
      record.errors.add(attribute, options[:message] || "deve estar no formato 00.000.000/0000-00")
      return
    end

    digits = value.gsub(/\D/, "").chars.map(&:to_i)
    return if digits.uniq.size > 1 && valid_check_digits?(digits)

    record.errors.add(attribute, options[:message] || "não é um CNPJ válido")
  end

  private

  def valid_check_digits?(digits)
    digits[12] == check_digit(digits.first(12)) && digits[13] == check_digit(digits.first(13))
  end

  def check_digit(digits)
    weights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2].last(digits.size)
    remainder = digits.zip(weights).sum { |digit, weight| digit * weight } % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
