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
          return broadcast(:invalid) if @form.invalid?

          transaction do
            import_project!
          end

          return broadcast(:invalid, broadcast_registry) if broadcast_registry.select { |hash| hash[:type] == :alert }.any?.present?

          broadcast(:ok, broadcast_registry)
        ensure
          broadcast_registry.clear
        end

        private

        attr_reader :f

        def import_project!
          resources = import_project_factory.prepare
          return import_project_factory.import! if errors_on_import(resources).blank?

          raise Decidim::BudgetsImporter::ImportErrors, @errors_on_import
        rescue Decidim::BudgetsImporter::ImportError => e
          (broadcast_registry << e.to_flash_format).flatten!
        rescue StandardError => e
          broadcast_registry << { type: :alert, message: "[Error #{e.class}] - #{e.message}" }
        end

        def import_project_factory
          @import_project_factory ||= Decidim::BudgetsImporter::Import::ImporterFactory.build(
            @form.document,
            @form.document.content_type,
            creator: Decidim::BudgetsImporter::Import::ProjectCreator,
            context: {
              current_component: @form.current_component,
              current_user: @form.current_user,
              budget: @form.budget
            }
          )
        end

        def broadcast_registry
          @broadcast_registry ||= []
        end

        def errors_on_import(resources)
          @errors_on_import ||= resources.select do |resource|
            (resource.is_a?(ImportError) && resource.try(:flash_msg_type) == :alert) || resource.is_a?(StandardError)
          end
        end
      end
    end
  end
end
