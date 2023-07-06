# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe BudgetsImporter do
    subject { described_class }

    it "has version" do
      expect(subject.version).to eq("2.0.0")
    end

    it "has decidim version" do
      expect(subject.decidim_version).to eq("0.27")
    end
  end
end
