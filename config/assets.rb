# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Shakapacker.register_path("#{base_path}/app/packs")
Decidim::Shakapacker.register_entrypoints(
  decidim_budgets_importer: "#{base_path}/app/packs/entrypoints/decidim_budgets_importer.js"
)
Decidim::Shakapacker.register_stylesheet_import("stylesheets/decidim/budgets_importer/budgets_importer")
