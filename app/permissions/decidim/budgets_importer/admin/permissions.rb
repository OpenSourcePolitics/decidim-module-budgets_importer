# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          return permission_action if permission_action.scope != :admin
          return permission_action unless user&.admin?

          allow! if can_access?
          allow! if can_import_projects?

          permission_action
        end

        def can_access?
          permission_action.subject == :budgets_importer &&
            permission_action.action == :read
        end

        def can_import_projects?
          permission_action.subject == :projects &&
            permission_action.action == :import
        end
      end
    end
  end
end
