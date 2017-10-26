require "spec_helper"

# to run specs with what"s remembered from vcr
#   $ rake
#
# to run specs with new fresh data from aws api calls
#   $ rake clean:vcr ; time rake
describe Jets::CLI do
  before(:all) do
    @args = "--noop"
  end

  describe "jets" do
    it "build" do
      out = execute("bin/jets build #{@args}")
      # puts out
      expect(out).to include("Building project")
    end
  end
end
