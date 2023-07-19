# frozen_string_literal: true

require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)

Decidim::Dev.dummy_app_path = File.expand_path(File.join("spec", "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"

def fixture_asset(name)
  File.expand_path(File.join(__dir__, "fixtures", "files", name))
end

# Public: Returns a file for testing, just like file fields expect it
def fixture_test_file(filename, content_type)
  Rack::Test::UploadedFile.new(fixture_asset(filename), content_type)
end
