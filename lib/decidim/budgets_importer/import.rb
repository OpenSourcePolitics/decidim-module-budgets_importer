# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Import
      autoload :ImporterFactory, "decidim/budgets_importer/import/importer_factory"
      autoload :Importer, "decidim/budgets_importer/import/importer"
      autoload :ProjectCreator, "decidim/budgets_importer/import/project_creator"
    end
  end
end
