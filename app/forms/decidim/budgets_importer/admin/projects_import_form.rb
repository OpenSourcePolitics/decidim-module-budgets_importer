# frozen_string_literal: true

module Decidim
  module BudgetsImporter
    module Admin
      # A form object used to import an assembly from the admin
      # dashboard.
      #
      class ProjectsImportForm < Form
        include Decidim::HasUploadValidations

        CSV_MIME_TYPE = "text/csv"
        JSON_MIME_TYPE = "application/json"
        XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        # Accepted mime types
        # keys: are used for dynamic help text on admin form.
        # values: are used to validate the file format of imported document.
        #
        # WARNING: consider adding/removing the relative translation key at
        # decidim.assemblies.admin.new_import.accepted_types when modifying this hash
        ACCEPTED_TYPES = {
          csv: CSV_MIME_TYPE,
          json: JSON_MIME_TYPE,
          xlsx: XLSX_MIME_TYPE
        }.freeze

        mimic :project

        attribute :document
        validates :document, presence: true
        validate :document_type_must_be_valid
        validate :document_must_have_content

        def document_text
          @document_text ||= document&.read
        end

        def document_type_must_be_valid
          return if valid_mime_types.include?(document_type)

          errors.add(:document, i18n_invalid_document_type_text)
        end

        def document_must_have_content
          return if document_text.present?

          errors.add(:document, i18n_empty_content)
        end

        # Return ACCEPTED_MIME_TYPES plus `text/plain` for better markdown support
        def valid_mime_types
          ACCEPTED_TYPES.values
        end

        def document_type
          document&.content_type
        end

        def i18n_invalid_document_type_text
          I18n.t("invalid_document_type",
                 scope: "activemodel.errors.models.assembly.attributes.document",
                 valid_mime_types: i18n_valid_mime_types_text)
        end
        def i18n_empty_content
          I18n.t("empty_content",
                 scope: "activemodel.errors.models.budgets_importer.attributes.document")
        end

        def i18n_valid_mime_types_text
          ACCEPTED_TYPES.keys.map do |mime_type|
            I18n.t(mime_type, scope: "decidim.assemblies.admin.new_import.accepted_types")
          end.join(", ")
        end
      end
    end
  end
end
