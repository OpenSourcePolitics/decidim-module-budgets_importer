# frozen_string_literal: true

require "decidim/budgets_importer/admin"
require "decidim/budgets_importer/engine"
require "decidim/budgets_importer/admin_engine"
require "decidim/budgets_importer/component"
require "decidim/budgets_importer/import"

module Decidim
  # This namespace holds the logic of the `BudgetsImporter` component. This component
  # allows users to create budgets_importer in a participatory space.
  module BudgetsImporter
    class ImportError < StandardError
      attr_writer :flash_msg_type

      def to_flash_format
        { type: flash_msg_type, message: message }
      end

      def flash_msg_type
        @flash_msg_type ||= :alert
      end
    end

    class ImportErrors < ImportError
      attr_accessor :errors

      def initialize(errors)
        @errors = errors
        super(I18n.t("errors", scope: "decidim.budgets_importer.errors.importer", errors_count: @errors.size))
      end

      def to_flash_format
        errors.each_with_object([{ type: flash_msg_type, message: message }]) do |error, array|
          error = ImportError.new(error.message) unless error.is_a?(ImportError)

          array << error.to_flash_format
        end
      end
    end

    class PGViolation < ImportError
      def initialize
        super(I18n.t("missing_arguments", scope: "decidim.budgets_importer.errors.database"))
      end
    end

    class DependencyNotFound < ImportError
      attr_accessor :resource
      attr_reader :id, :project_title

      def initialize(i18n_key)
        super(I18n.t(i18n_key, scope: "decidim.budgets_importer.errors.#{resource}", project_title: @project_title, id: @id))
      end
    end

    class CategoryNotFound < DependencyNotFound
      def initialize(project_title, id)
        @project_title = project_title
        @id = id
        @resource = "category"
        super("not_found")
      end
    end

    class ProposalNotFound < DependencyNotFound
      attr_reader :ids

      def initialize(project_title, ids)
        @project_title = project_title
        @ids = ids
        @id = ids.join(",")
        @resource = "proposal"
        super("not_found")
      end
    end
  end
end
