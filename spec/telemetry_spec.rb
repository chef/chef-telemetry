require "spec_helper"

RSpec.describe Telemetry do
  it "has a version number" do
    expect(Telemetry::VERSION).not_to be nil
  end

end
