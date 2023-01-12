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
      attr_accessor :flash_msg_type

      def initialize(message)
        super(message)
      end
    end

    class DependencieNotFound < ImportError
      attr_accessor :resource
      attr_reader :id, :project_title, :flash_msg_type

      def initialize(i18n_key)
        @flash_msg_type = :alert

        super(I18n.t(i18n_key, scope: "decidim.budgets_importer.errors.#{resource}", project_title: @project_title, id: @id))
      end

      def to_flash_format
        { type: @flash_msg_type, message: self.message }
      end

      def flash_msg_type
        @flash_msg_type ||= :alert
      end
    end

    class CategoryNotFound < DependencieNotFound
      def initialize(project_title, id)
        @project_title = project_title
        @id = id
        @resource = "category"
        super("not_found")
      end
    end

    class ProposalNotFound < DependencieNotFound
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
