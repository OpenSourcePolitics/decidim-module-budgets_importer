# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Admin
      class ProjectsImportsController < ApplicationController
        helper_method :budget

        def new
          enforce_permission_to :import, :projects
          @form = form(Decidim::BudgetsImporter::Admin::ProjectsImportForm).instance
        end

        def create
          enforce_permission_to :import, :projects

          @form = form(Decidim::BudgetsImporter::Admin::ProjectsImportForm).from_params(params)

          ImportProject.call(@form) do
            on(:ok) do
              flash[:notice] = "Import succeeded"

              render :new
            end

            on(:invalid) do |registry|
              registry&.each do |hash|
                flash_key = if hash[:type] == :alert
                              hash[:type]
                            else
                              "#{hash[:type]}_#{rand(1...1000)}"
                            end

                flash.now[flash_key] = hash[:message]
              end
              flash.now[:alert] ||= "C'est pas bon"

              render :new
            end

            on(:empty_file) do
              flash.now[:alert] = "Le fichier semble vide..."
              render :new
            end
          end
        end

        private

        def budget
          @budget ||= Decidim::Budgets::Budget.where(component: current_component).find_by(id: params[:budget_id])
        end
      end
    end
  end
end
