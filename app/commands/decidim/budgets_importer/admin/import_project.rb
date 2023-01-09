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
        rescue Decidim::BudgetsImporter::ProposalNotFound => e
          broadcast_registry << { type: :alert, message: "Proposals not found for project '#{e.project_title}' : ids '#{e.ids.join(",")}'" }
        rescue Decidim::BudgetsImporter::CategoryNotFound => e
          broadcast_registry << { type: :alert, message: "Category ID:'#{e.id}' not found for project '#{e.project_title}'" }
        rescue StandardError => e
          broadcast_registry << { type: :alert, message: "Unexpected error occurred '#{e.class}' for project ''" }
        end

        def projects_h
          @projects_h ||= JSON.parse(import_form.document_text)
        end

        def new_project(hash)
          project_h = {
            component: current_component,
            title: hash["title"],
            description: hash["description"],
            proposal_ids: related_proposals_ids(hash),
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

          raise Decidim::BudgetsImporter::CategoryNotFound.new("Category not found", hash["title"][current_user.locale], hash.dig("category", "id"))
        end

        def broadcast_registry
          @broadcast_registry ||= []
        end

        def related_proposals_ids(hash)
          related_proposals = hash.fetch("related_proposals", [])
          proposals = Decidim.find_resource_manifest(:proposals).try(:resource_scope, current_component)&.where(id: related_proposals)&.order(title: :asc)
          proposals_ids = proposals.map(&:id)

          unless (related_proposals - proposals_ids).empty?
            raise Decidim::BudgetsImporter::ProposalNotFound.new("Proposals not found", hash["title"][current_user.locale], (related_proposals - proposals_ids))
          end

          proposals_ids
        end
      end
    end
  end
end
