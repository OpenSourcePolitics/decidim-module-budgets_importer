# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe BudgetsImporter::ImportError do
    subject { described_class.new message }

    let(:message) { "Import error" }

    it "is a StandardError" do
      expect(subject).to be_a StandardError
    end

    describe "#flash_msg_type" do
      subject { described_class.new(message).flash_msg_type }

      it { is_expected.to eq(:alert) }
    end

    describe "#to_flash_format" do
      subject { described_class.new(message).to_flash_format }

      it { is_expected.to eq({ type: :alert, message: message }) }
    end
  end

  describe BudgetsImporter::ImportErrors do
    subject { described_class.new errors }

    let(:errors) do
      [
        BudgetsImporter::ImportError.new(message_1),
        BudgetsImporter::ImportError.new(message_2)
      ]
    end
    let(:message_1) { "First import error" }
    let(:message_2) { "Second import error" }

    it "is a ImportError" do
      expect(subject).to be_a BudgetsImporter::ImportError
    end

    describe "#errors" do
      subject { described_class.new(errors).errors }

      it { is_expected.to match(errors) }
    end

    describe "#flash_msg_type" do
      subject { described_class.new(errors).flash_msg_type }

      it { is_expected.to eq(:alert) }
    end

    describe "#to_flash_format" do
      subject { described_class.new(errors).to_flash_format }

      it "serializes errors" do
        expect(subject).to match([
                                   { type: :alert, message: "Canceling import because of 2 errors" },
                                   { type: :alert, message: "First import error" },
                                   { type: :alert, message: "Second import error" }
                                 ])
      end
    end
  end

  describe BudgetsImporter::DependencyNotFound do
    subject { described_class.new i18n_key }

    let(:i18n_key) { "not_found" }

    it "is a ImportError" do
      expect(subject).to be_a BudgetsImporter::ImportError
    end
  end

  describe BudgetsImporter::CategoryNotFound do
    subject { described_class.new project_title, id }

    let(:project_title) { "Project title example" }
    let(:id) { 10 }

    it "is a DependencyNotFound" do
      expect(subject).to be_a BudgetsImporter::DependencyNotFound
    end

    describe "#to_flash_format" do
      subject { described_class.new(project_title, id).to_flash_format }

      it { is_expected.to eq({ type: :alert, message: "Category (ID: 10) does not exist for project 'Project title example'" }) }
    end
  end

  describe BudgetsImporter::ProposalNotFound do
    subject { described_class.new project_title, ids }

    let(:project_title) { "Project title example" }
    let(:ids) { [10, 11] }

    it "is a DependencyNotFound" do
      expect(subject).to be_a BudgetsImporter::DependencyNotFound
    end

    describe "#to_flash_format" do
      subject { described_class.new(project_title, ids).to_flash_format }

      it { is_expected.to eq({ type: :alert, message: "Related proposals (ID: 10,11) does not exist for project 'Project title example'" }) }
    end
  end
end
