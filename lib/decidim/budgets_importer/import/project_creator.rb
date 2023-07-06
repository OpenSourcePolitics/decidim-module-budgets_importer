# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Import
      # This class is responsible for creating the imported proposal answers
      # and must be included in proposals component's import manifest.
      class ProjectCreator < Decidim::Admin::Import::Creator
        def self.resource_klass
          Decidim::Budgets::Project
        end

        # Add new project to budget and link related proposals
        def produce
          check_required_params!

          related_proposals(resource)
          resource
        end

        def finish!
          Decidim.traceability.perform_action!(
            "create",
            resource,
            current_user
          ) do
            resource.save!
            link_proposals!
          end
        end

        private

        def resource
          @resource ||= Decidim::Budgets::Project.new(
            component: component,
            budget: budget,
            title: title,
            scope: scope,
            category: category,
            description: description,
            budget_amount: budget_amount
          )
        end

        def id
          data[:id].to_i
        end

        def title
          locale_hasher("title", available_locales + ["machine_translations"])
        end

        def description
          locale_hasher("description", available_locales + ["machine_translations"])
        end

        def category_id
          data[:"category/id"]&.to_i
        end

        def scope_id
          data[:"scope/id"]&.to_i
        end

        def budget_amount
          data[:budget_amount]
        end

        def proposal_ids
          return [data[:related_proposals].to_i] if data[:related_proposals].is_a? Float

          data[:related_proposals]
            &.split(",")
            &.flatten
            &.map(&:to_i) || []
        end

        def component
          context[:current_component]
        end

        def budget
          context[:budget]
        end

        def current_user
          context[:current_user]
        end

        # ProjectForm requires the category_id to be present in component, if not returns nil
        def category
          return if category_id.blank?

          category = component.categories.find_by(id: category_id)
          return category if category.present?

          raise Decidim::BudgetsImporter::CategoryNotFound.new(title[current_user.locale], category_id)
        end

        # ProjectForm requires the category_id to be present in component, if not returns nil
        def scope
          return unless component.scopes_enabled? || scope_id.present?

          component.scopes.find_by(id: scope_id).presence
        end

        def link_proposals!
          resource.link_resources(@proposals, "included_proposals")
        end

        def related_proposals(project)
          proposals = project.sibling_scope(:proposals).where(id: proposal_ids)
          missing_ids = proposal_ids - proposals.map(&:id)
          raise Decidim::BudgetsImporter::ProposalNotFound.new(title[current_user.locale], missing_ids) if missing_ids.present?

          @proposals = proposals
        end

        def available_locales
          @available_locales ||= component.organization.available_locales
        end

        def locale_hasher(field, locales)
          locales.each_with_object({}) do |locale, hash|
            parsed = if locale == "machine_translations"
                       locale_hasher("#{field}/machine_translations", locales - ["machine_translations"])
                     else
                       data[:"#{field}/#{locale}"]
                     end
            hash[locale] = parsed unless parsed.nil?
          end
        end

        def check_required_params!
          raise ImportError, I18n.t("title", scope: "decidim.budgets_importer.command.import.missing") if title.blank?
          raise ImportError, I18n.t("description", scope: "decidim.budgets_importer.command.import.missing") if description.blank?
          raise ImportError, I18n.t("budget_amount", scope: "decidim.budgets_importer.command.import.missing") if budget_amount.blank?
        end
      end
    end
  end
end
