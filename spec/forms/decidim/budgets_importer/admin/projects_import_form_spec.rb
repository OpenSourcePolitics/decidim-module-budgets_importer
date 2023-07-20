# frozen_string_literal: true

require "spec_helper"

module Decidim
  module BudgetsImporter
    module Admin
      describe ProjectsImportForm do
        subject { form }

        let(:document) { upload_test_file(Decidim::Dev.test_file("import_proposals.csv", mime_type)) }
        let(:mime_type) { "text/csv" }
        let(:component) { create(:component) }
        let(:params) do
          {
            document: document
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: component,
            current_participatory_space: component.participatory_space
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when document is not present" do
          let(:document) { nil }

          it { is_expected.to be_invalid }
        end

        context "when mime type is JSON" do
          let(:mime_type) { "application/json" }

          it { is_expected.to be_valid }
        end

        context "when mime type is xlsx" do
          let(:mime_type) { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
