# frozen_string_literal: true

# The built-in PDF fonts (Helvetica) cover pt-BR accents via Windows-1252;
# suppress Prawn's multilingualization warning about them.
Prawn::Fonts::AFM.hide_m17n_warning = true
