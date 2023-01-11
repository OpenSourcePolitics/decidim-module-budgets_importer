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
    class ProposalNotFound < StandardError
      attr_reader :ids, :project_title

      def initialize(message, project_title, ids)
        # Call the parent's constructor to set the message
        super(message)

        # Store the action in an instance variable
        @project_title = project_title
        @ids = ids
      end
    end
    class CategoryNotFound < StandardError
      attr_reader :id, :project_title

      def initialize(message, project_title, id)
        # Call the parent's constructor to set the message
        super(message)

        # Store the action in an instance variable
        @project_title = project_title
        @id = id
      end
    end
  end
end
