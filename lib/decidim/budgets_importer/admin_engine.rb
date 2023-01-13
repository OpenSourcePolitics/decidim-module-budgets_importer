# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    # This is the engine that runs on the public interface of `BudgetsImporter`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::BudgetsImporter::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      initializer "decidim_budgets_importer.admin_mount_routes" do
        Decidim::Budgets::AdminEngine.routes do
          resources :budgets do
            resources :projects do
              collection do
                resources :projects_import, controller: "/decidim/budgets_importer/admin/projects_imports", only: [:new, :create, :show]
              end
            end
          end
        end
      end

      def load_seed
        nil
      end
    end
  end
end
