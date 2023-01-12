# frozen_string_literal: true

require "spec_helper"

module Decidim
  module BudgetsImporter
    module Admin
      describe ImportProject do
        describe "call" do
          let(:organization) { create :organization }
          let(:current_user) { create :user, :admin, :confirmed, organization: organization }
          let(:participatory_process) { create :participatory_process, organization: organization }
          let(:current_component) { create(:component, manifest_name: :budgets, participatory_space: participatory_process) }
          let!(:proposals) do
            (1..3).map { |idx| build(:proposal, :accepted, id: idx, decidim_component_id: current_component.id).tap { |proposal| proposal.save(validate: false) } }
          end
          let!(:proposal) { proposals.first }
          let(:budget) { create :budget, component: current_component }
          let!(:category) { create(:category, id: 1, participatory_space: current_component.participatory_space) }
          let(:document) { fixture_file_upload file_fixture(filename), mime_type }
          let(:filename) { "projects-import.json" }
          let(:mime_type) { "application/json" }
          let(:valid) { true }
          let!(:form) do
            double(
              valid?: valid,
              invalid?: !valid,
              current_component: current_component,
              current_user: current_user,
              budget: budget,
              document: document,
              document_text: document.read
            )
          end

          let(:command) { described_class.new(form) }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates the projects" do
            expect do
              command.call
            end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(1)
          end

          describe "when document is CSV" do
            let(:filename) { "projects-import.csv" }
            let(:mime_type) { "text/csv" }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates the projects" do
              expect do
                command.call
              end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(1)
            end
          end

          describe "when the form is invalid" do
            let(:valid) { false }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the project" do
              expect do
                command.call
              end.to change(Decidim::Budgets::Project, :count).by(0)
            end
          end

          context "when category id does not exist" do
            let(:category) { create(:category) }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end
          end
        end
      end
    end
  end
end
