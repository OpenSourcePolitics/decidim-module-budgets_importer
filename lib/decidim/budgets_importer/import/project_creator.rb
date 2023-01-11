# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Import
      # This class is responsible for creating the imported proposal answers
      # and must be included in proposals component's import manifest.
      class ProjectCreator < Decidim::Admin::Import::Creator
        # Retuns the resource class to be created with the provided data.
        def self.resource_klass
          Decidim::Budgets::Project
        end

        # Add new project to budget and link related proposals
        def produce
          resource
        end

        def finish!
          Decidim.traceability.perform_action!(
            "project",
            resource,
            current_user
          ) do
            resource.save!
            link_proposals_for!(resource)
          end
        end

        private

        def resource
          @resource ||= begin
            Decidim::Budgets::Project.new(
              component: component,
              budget: budget,
              title: title,
              scope: scope,
              category: category,
              description: description,
              budget_amount: budget_amount
            )
          end
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
          data[:related_proposals]&.split(",")
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

        # ProjectForm requires the category_id to be present in @f.current_component, if not returns nil
        def category
          category = component.categories.find_by(id: category_id)
          return category if category.present?

          raise Decidim::BudgetsImporter::CategoryNotFound.new("Category not found", title[current_user.locale], category_id)
        end

        # ProjectForm requires the category_id to be present in @f.current_component, if not returns nil
        def scope
          component.scopes.find_by(id: scope_id) || component.scope
        end

        def link_proposals_for!(project)
          proposals = project.sibling_scope(:proposals).where(id: proposal_ids)
          project.link_resources(proposals, "included_proposals")
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
      end
    end
  end
end