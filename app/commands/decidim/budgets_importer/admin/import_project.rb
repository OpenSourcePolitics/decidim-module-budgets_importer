# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Admin
      # A command with all the business logic to import a new project
      # in the system.
      class ImportProject < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # assembly - An assembly we want to duplicate
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        # - :empty_file if the imported file is blank
        # - :proposal_not_found if a related proposal is inexistant in database
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?
          return broadcast(:empty_file) if projects_h.blank?

          @broadcast_registry = []

          transaction do
            import_project_from(projects_h)
          end
          return broadcast(:invalid, @broadcast_registry) if @broadcast_registry.present?

          broadcast(:ok)
        end

        private

        attr_reader :form

        def import_project_from(list)
          list.each do |hash|
            project = create_project!(hash)
            next if hash["related_proposals"].blank?

            Decidim::Proposals::Proposal.find(hash["related_proposals"])&.each do |proposal|
              create_resource_link!(project, proposal)
            end
          rescue ActiveRecord::RecordNotFound => e
            case e.model.parameterize.underscore
            when "decidim_budgets_project"
              @broadcast_registry << { type: :alert, message: I18n.t(".error.decidim_budgets_project", scope: "decidim.budgets_importer.command.import") }
            when "decidim_proposals_proposal"
              @broadcast_registry << { type: :alert, message: I18n.t(".error.decidim_proposals_proposal", scope: "decidim.budgets_importer.command.import") }
            else
              @broadcast_registry << { type: :alert, message: I18n.t(".error.unexpected", scope: "decidim.budgets_importer.command.import") }
            end

              # "Proposal (ID/#{e.id}) not found for project '#{hash["title"][current_user.locale]}'" }
          rescue StandardError => e
            @broadcast_registry << { type: :alert, message: "Unexpected error occurred '#{e.class}' for project '#{hash["title"][current_user.locale]}'" }
          end
        end

        def projects_h
          @projects_h ||= JSON.parse(form.document_text)
        end

        def create_resource_link!(project, proposal, to_type = "Decidim::Proposals::Proposal", name = "included_proposals")
          Decidim::ResourceLink.create(
            from_type: project.class,
            from_id: project.id,
            to_type: to_type,
            to_id: proposal.id,
            name: name,
            data: {}
          )
        end

        def create_project!(hash)
          Decidim::Budgets::Project.create(component: current_component,title: hash["title"],description: hash["description"],budget_amount: hash["budget_amount"],scope: find_scope_by_id(hash),category: find_category_by_id(hash),budget: budget)
        end

        def find_scope_by_id(hash)
          return unless hash.dig("scope", "id").is_a? Integer

          Decidim::Scope.find(hash.dig("scope", "id"))
        rescue ActiveRecord::RecordNotFound => e
          @broadcast_registry << { type: :scope_not_found, message: "Scope (ID/#{e.id}) not found for project '#{hash["title"][current_user.locale]}'" }
          nil
        end

        def find_category_by_id(hash)
          return unless hash.dig("category", "id").is_a? Integer

          Decidim::Category.find(hash.dig("category", "id"))
        rescue ActiveRecord::RecordNotFound => e
          @broadcast_registry << { type: :category_not_found, message: "Category (ID/#{e.id}) not found for project '#{hash["title"][current_user.locale]}'" }
          nil
        end

        # Returns first error as symbol or empty array
        def error_on_import
          @error_on_import ||= @imported.uniq.reject { |status| status == :ok }.first
        end
      end
    end
  end
end
