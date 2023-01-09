# frozen_string_literal: true

require "decidim/budgets_importer/admin"
require "decidim/budgets_importer/engine"
require "decidim/budgets_importer/admin_engine"
require "decidim/budgets_importer/component"

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
  end
end
