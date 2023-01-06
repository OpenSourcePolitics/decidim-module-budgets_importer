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
        #
        # Returns nothing.
        def call
          # TODO:
          # - Check errors on form
          # - Broadcast custom message depending on form error
          # Ex: Bad format for CSV
          return broadcast(:invalid) if form.invalid?
          return broadcast(:empty_file) if projects_h.blank?

          transaction do
            robo = import_project_from(projects_h)
          end

          broadcast(:ok)
        end

        private

        attr_reader :form

        # TODO: Enable import for CSV / Excel
        def import_project_from(list)
          list.map do |hash|
            category = Decidim::Category.find(hash["category"]["id"])
            scope = Decidim::Scope.find(hash["scope"]["id"])

            project = Decidim::Budgets::Project.create(
              component: current_component,
              title: hash["title"],
              description: hash["description"],
              budget_amount: hash["budget_amount"],
              scope: scope,
              category: category,
              budget: budget)
            project.reload

            next :ok if hash["related_proposals"].blank?
            proposals = Decidim::Proposals::Proposal.find(hash["related_proposals"])
            next :proposal_not_found if proposals.blank?
            proposals.each do |proposal|
              return :proposal_not_found if proposal.blank?
              Decidim::ResourceLink.create(
                from_type: project.class,
                from_id: project.id,
                to_type: "Decidim::Proposals::Proposal",
                to_id: proposal.id,
                name: "included_proposals",
                data: {}
              )
            end

            :ok
          end
        end

        def projects_h
          @projects_h ||= JSON.parse(form.document_text)
        end
      end
    end
  end
end
