# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")
Decidim::Webpacker.register_entrypoints(
  decidim_budgets_importer: "#{base_path}/app/packs/entrypoints/decidim_budgets_importer.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/budgets_importer/budgets_importer")
