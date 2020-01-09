require "spec_helper"
require "chef/telemetry/decision"

RSpec.describe Chef::Telemetry::Decision do
  it "has a version number" do
    expect(Chef::Telemetry::VERSION).not_to be nil
  end

  let(:output) do
    d = StringIO.new
    allow(d).to receive(:isatty).and_return(true)
    d
  end
  let(:opts) { { output: output } }
  let(:dec) { Chef::Telemetry::Decision.new(opts) }

  def check_option_behavior(opts = { should_opt_in: false } )
    expect(dec.check_and_persist).to eq(opts[:should_opt_in])
    expect(output.string).to eq("")
  end

  describe "#check_and_persist" do
    let(:env_dec) { instance_double(Chef::Telemetry::Decision::Environment) }
    let(:file_dec) { instance_double(Chef::Telemetry::Decision::File) }

    before do
      expect(Chef::Telemetry::Decision::Environment).to receive(:new).and_return(env_dec)
      expect(Chef::Telemetry::Decision::File).to receive(:new).and_return(file_dec)

      # Default all mock decisions to false
      allow(env_dec).to receive(:opt_out?).and_return(false)
      allow(env_dec).to receive(:opt_in?).and_return(false)
      allow(file_dec).to receive(:opt_out?).and_return(false)
      allow(file_dec).to receive(:opt_in?).and_return(false)
    end

    describe "when the user expresses intent as an environment variable" do
      describe "when intent is opt-in" do
        before { allow(env_dec).to receive(:opt_in?).and_return(true) }
        it "opts in silently" do
          check_option_behavior(should_opt_in: true)
        end
      end

      describe "when intent is opt-out" do
        before { allow(env_dec).to receive(:opt_out?).and_return(true) }
        it "opts out silently" do
          check_option_behavior(should_opt_in: false)
        end
      end
    end

    describe "when the user expresses intent as a file" do
      describe "when intent is opt-in" do
        before { allow(file_dec).to receive(:opt_in?).and_return(true) }
        it "opts in silently" do
          check_option_behavior(should_opt_in: true)
        end
      end

      describe "when intent is opt-out" do
        before { allow(file_dec).to receive(:opt_out?).and_return(true) }
        it "opts out silently" do
          check_option_behavior(should_opt_in: false)
        end
      end
    end
  end
end
