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
          let!(:category_1) { create(:category, id: 1, participatory_space: current_component.participatory_space) }
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
          let(:document) { fixture_file_upload file_fixture(filename), mime_type }
          let(:filename) { "projects-import.json" }
          let(:mime_type) { "application/json" }
          let(:valid) { true }
          let(:command) { described_class.new(form) }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates the projects" do
            expect do
              command.call
            end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(3)
          end

          describe "#projects_h" do
            let(:expected_h) do
              [
                {
                  "id" => 1,
                  "category" => {
                    "id" => 1,
                    "name" => {
                      "ca" => "Impedit quasi inventore sint quibusdam.",
                      "en" => "Est dolorem mollitia sed aperiam.",
                      "machine_translations" => {
                        "es" => "Et accusamus omnis laboriosam sapiente."
                      }
                    }
                  },
                  "scope" => {
                    "id" => 17,
                    "name" => {
                      "ca" => "Lake Cory",
                      "en" => "Lake Cory",
                      "es" => "Lake Cory"
                    }
                  },
                  "participatory_space" => {
                    "id" => 1,
                    "url" => "http://localhost:3000/processes/transfer-push?participatory_process_slug=transfer-push"
                  },
                  "component" => {
                    "id" => 4
                  },
                  "title" => {
                    "ca" => "Quae recusandae.",
                    "en" => "Example title",
                    "es" => "",
                    "machine_translations" => {
                      "es" => "Quos reiciendis."
                    }
                  },
                  "description" => {
                    "ca" => "<p>Enim nesciunt amet. Tenetur provident debitis. Quisquam pariatur repellat.</p>",
                    "en" => "<p>Example description</p>",
                    "es" => "",
                    "machine_translations" => {
                      "es" => "<p>Doloremque ut distinctio. Laudantium amet distinctio. Qui non ipsam.</p>"
                    }
                  },
                  "budget" => {
                    "id" => 1
                  },
                  "budget_amount" => 71_662_666,
                  "confirmed_votes" => 0,
                  "comments" => 2,
                  "created_at" => "2023-01-10 15:48:12 UTC",
                  "url" => "http://localhost:3000/processes/transfer-push/f/4/budgets/1/projects/1",
                  "related_proposals" => [
                    1
                  ],
                  "related_proposal_titles" => [
                    "Proposal title example"
                  ],
                  "related_proposal_urls" => [
                    "http://localhost:3000/processes/transfer-push/f/3/proposals/1"
                  ]
                }
              ]
            end

            it "serializes the document content to Hash" do
              expect(command.send(:projects_h)).to eq(expected_h)
            end

            context "when document is CSV" do
              let(:filename) { "projects-import.csv" }
              let(:mime_type) { "text/csv" }

              it "serializes the document content to Hash" do
                expect(command.send(:projects_h)).to eq(expected_h)
              end
            end
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
              end.to change { Decidim::Budgets::Project.where(budget: budget).count }.by(3)
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
        end
      end
    end
  end
end
