# frozen_string_literal: true

# Pagy initializer
# See https://ddnexus.github.io/pagy/docs/configuration

require 'pagy'
require 'pagy/extras/i18n'
require 'pagy/extras/overflow'

# Default number of items per page
Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:overflow] = :last_page # Go to last page if page is out of range

# I18n
Pagy::I18n.load(locale: 'pt-BR')
