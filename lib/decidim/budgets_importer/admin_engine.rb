# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    # This is the engine that runs on the public interface of `BudgetsImporter`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::BudgetsImporter::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :budgets_importer do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "budgets_importer#index"
      end

      def load_seed
        nil
      end
    end
  end
end
