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
          # TODO: This is a hack with the collection's 0.26 method we need to modify it to use the new 0.27 method using the process_file_locally (Check importer.rb in 0.27)
          @prepare ||= collection_budgets.map do |project_creator|
            project_creator.produce
          rescue StandardError => e
            next e
          end
        end

        # Save resources based on prepare method
        def import!
          collection_budgets.map(&:finish!)
        end

        def collection_budgets
          @collection ||= collection_budgets_data.map { |item| creator.new(item, context) }
        end

        def collection_budgets_data
          return @collection_data if @collection_data

          @collection_data = []
          reader.new(file).read_rows do |rowdata, index|
            if index.zero?
              @data_headers = rowdata.map { |d| d.to_s.to_sym }
            else
              @collection_data << rowdata.each_with_index.to_h do |val, ind|
                [@data_headers[ind], val]
              end
            end
          end

          @collection_data
        end
      end
    end
  end
end
