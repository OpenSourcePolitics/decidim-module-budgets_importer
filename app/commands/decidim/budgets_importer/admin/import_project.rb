# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Admin
      # A command with all the business logic to import a new project
      # in the system.
      class ImportProject < Rectify::Command
        include Decidim::FormFactory
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # assembly - An assembly we want to duplicate
        def initialize(import_form)
          @import_form = import_form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the import_form wasn't valid and we couldn't proceed.
        # - :empty_file if the imported file is blank
        # - :proposal_not_found if a related proposal is inexistant in database
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if import_form.invalid?
          return broadcast(:empty_file) if projects_h.blank?

          transaction do
            import_project_from(projects_h)
          end

          return broadcast(:invalid, broadcast_registry) if broadcast_registry.select { |hash| hash[:type] == :alert }.any?.present?

          broadcast(:ok, broadcast_registry)
        ensure
          broadcast_registry.clear
        end

        private

        attr_reader :import_form

        def import_project_from(list)
          list.each { |hash| new_project(hash) }
        rescue StandardError => e
          broadcast_registry << { type: :alert, message: "Unexpected error occurred '#{e.class}' for project '#{hash["title"][current_user.locale]}'" }
        end
      end

      def projects_h
        @projects_h ||= JSON.parse(import_form.document_text)
      end

      def new_project(hash)
        project_h = {
          component: current_component,
          title: hash["title"],
          description: hash["description"],
          proposal_ids: hash.fetch("related_proposals", []),
          budget_amount: hash["budget_amount"],
          decidim_scope_id: hash.dig("scope", "id"),
          decidim_category_id: category_id(hash)
        }

        form = form(Decidim::BudgetsImporter::Admin::ProjectForm).from_params(project_h, component: current_component, budget: budget)
        Decidim::Budgets::Admin::CreateProject.call(form) do
          on(:invalid) do
            broadcast_registry << { type: :alert, message: "Project '#{hash["title"][current_user.locale]}' is invalid : #{form.errors.map { |k, v| "#{k} #{v}" }.first} " }
          end
        end
      end

      # ProjectForm requires the category_id to be present in current_component, if not returns nil
      def category_id(hash)
        return hash.dig("category", "id") if current_component.categories.find_by(id: hash.dig("category", "id")).present?

        broadcast_registry << {
          type: :warning,
          message: "Project '#{hash.dig("title", current_user.locale)}' : Category '#{hash.dig("category", "name", current_user.locale)}' does not exist on this component"
        }
        nil
      end

      def broadcast_registry
        @broadcast_registry ||= []
      end
    end
  end
end
