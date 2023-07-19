# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module BudgetsImporter
    # This is the engine that runs on the public interface of budgets_importer.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::BudgetsImporter

      routes do
        # Add engine routes here
        # resources :budgets_importer
        # root to: "budgets_importer#index"
      end

      initializer "BudgetsImporter.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "Decidim.disable_strong_password" do
        Decidim.config.admin_password_strong = false
      end
    end
  end
end
