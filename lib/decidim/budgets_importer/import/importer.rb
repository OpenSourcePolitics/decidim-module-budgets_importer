# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Import
      # Class providing the interface and implementation of an importer. Needs
      # a reader to be passed to the constructor which handles the import file
      # reading depending on its type.
      #
      # You can also use the ImporterFactory class to create an Importer
      # instance.
      class Importer < Decidim::Admin::Import::Importer
        def prepare
          @prepare ||= collection.map do |project_creator|
            project_creator.produce
          rescue StandardError => e
            next e
          end
        end

        # Save resources based on prepare method
        def import!
          collection.map(&:finish!)
        end
      end
    end
  end
end
