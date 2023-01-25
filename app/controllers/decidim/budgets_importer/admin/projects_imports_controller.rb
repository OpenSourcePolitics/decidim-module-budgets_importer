# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Admin
      class ProjectsImportsController < Decidim::BudgetsImporter::Admin::ApplicationController
        helper_method :budget, :budget_projects_import_index_path

        def new
          enforce_permission_to :import, :projects
          @form = form(Decidim::BudgetsImporter::Admin::ProjectsImportForm).instance
        end

        def show
          render :new
        end

        def create
          enforce_permission_to :import, :projects

          @form = form(Decidim::BudgetsImporter::Admin::ProjectsImportForm).from_params(params, budget: budget)

          ImportProject.call(@form) do
            on(:ok) do |broadcast_registry|
              broadcast_registry&.each do |hash|
                flash.now["#{hash[:type]}_#{rand(1...1000)}"] = hash[:message]
              end
              flash[:notice] = I18n.t("success", scope: "decidim.budgets_importer.import")

              redirect_to budget_projects_path(budget)
            end

            on(:invalid) do |registry|
              registry&.each do |hash|
                flash_key = if hash[:type] == :alert && flash.now[:alert].blank?
                              hash[:type]
                            else
                              "#{hash[:type]}_#{rand(1...1000)}"
                            end

                flash.now[flash_key] = hash[:message]
              end

              render :new
            end
          end
        end

        private

        def budget
          @budget ||= Decidim::Budgets::Budget.where(component: current_component).find_by(id: params[:budget_id])
        end

        def budget_projects_import_index_path(budget)
          send(current_component.mounted_admin_engine).budget_projects_import_index_path(budget)
        end

        def budget_projects_path(budget)
          send(current_component.mounted_admin_engine).budget_projects_path(budget)
        end
      end
    end
  end
end
