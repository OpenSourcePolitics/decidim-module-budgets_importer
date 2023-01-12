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
          let!(:proposal_component) { create(:proposal_component, participatory_space: participatory_process) }
          let!(:proposal) { create(:proposal, id: 1, component: proposal_component) }
          let!(:proposal_2) { create(:proposal, id: 2, component: proposal_component) }
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
            end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(2)
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
              end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(2)
            end
          end

          describe "when document is CSV" do
            let(:filename) { "projects-import.xlsx" }
            let(:mime_type) { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates the projects" do
              expect do
                command.call
              end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(2)
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

          context "when category ID does not exist" do
            let(:category) { create(:category) }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the project" do
              expect do
                command.call
              end.to change(Decidim::Budgets::Project, :count).by(0)
            end
          end

          context "when related proposal ID does not exist in participatory space" do
            let!(:proposal) { create(:proposal, id: 1) }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the project" do
              expect do
                command.call
              end.to change(Decidim::Budgets::Project, :count).by(0)
            end
          end

          context "when one of related proposals ID does not exist" do
            let!(:proposal) { create(:proposal, id: 10, component: proposal_component) }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the project" do
              expect do
                command.call
              end.to change(Decidim::Budgets::Project, :count).by(0)
            end
          end
        end
      end
    end
  end
end
