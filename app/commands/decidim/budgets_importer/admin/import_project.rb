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

          return broadcast(:invalid, broadcast_registry.critical_exceptions) if broadcast_registry.invalid?

          broadcast(:ok, broadcast_registry.registry)
        end

        def broadcast_registry
          @broadcast_registry ||= Class.new do
            attr_reader :registry

            def initialize
              @registry = []
            end

            # Param obj can be Hash or Array of Hash
            def register!(obj)
              (@registry << obj).flatten!
            end

            def invalid?
              critical_exceptions.any?
            end

            def critical_exceptions
              @critical_exceptions ||= @registry.select { |hash| hash[:type] == :alert }
            end
          end.new
        end

        private

        attr_reader :f

        def import_project!
          # Prepare projects before import
          resources = import_project_factory.prepare
          # If one of all projects is invalid it cancels import and raise error
          return import_project_factory.import! if errors_on_import(resources).blank?

          raise Decidim::BudgetsImporter::ImportErrors, @errors_on_import
        rescue Decidim::BudgetsImporter::ImportError => e
          byebug
          broadcast_registry.register!(e.to_flash_format)
        rescue StandardError => e
          broadcast_registry.register!({ type: :alert, message: "[Error #{e.class}] - #{e.message}" })
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

        def errors_on_import(resources)
          @errors_on_import ||= resources.select do |resource|
            (resource.is_a?(ImportError) && resource.try(:flash_msg_type) == :alert) || resource.is_a?(StandardError)
          end
        end
      end
    end
  end
end
