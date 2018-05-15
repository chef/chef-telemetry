require "spec_helper"

RSpec.describe Telemetry::Decision do
  let(:env) { {} }
  let(:env_pwd) { "/path/to/cwd" }
  let(:home) { "/Users/chef_user" }

  before do
    stub_const("ENV", env)

    if ChefConfig.windows?
      env["CD"] = env_pwd
    else
      env["PWD"] = env_pwd
    end

    allow(ChefConfig::PathHelper).to receive(:home).with(".chef").and_return(File.join(home, ".chef"))
  end

  describe "#local_opt_out" do
    it "returns true if it finds an opt out file" do
      expect(File).to receive(:exist?).with(File.join(env_pwd, ".chef/telemetry_opt_out")).and_return true
      expect(subject.local_opt_out?).to be true
    end
  end

  context "a user decision" do
    describe "#user_opted_out?" do
      it "returns true if an opt out file exists in the users home directory" do
        expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_out").and_return true
        expect(subject.user_opted_out?).to be true
      end
    end

    describe "#user_opted_in?" do
      it "returns true if an opt in file exists in the users home directory" do
        expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_in").and_return true
        expect(subject.user_opted_in?).to be true
      end
    end
  end

  describe "#opt_out?" do
    before do
      %w{ / /path/ /path/to/ /path/to/cwd/ }.each do |pth|
        allow(File).to receive(:exist?).with("#{pth}.chef/telemetry_opt_out").and_return false
      end
      allow(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_out").and_return false
      allow(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_in").and_return false
    end

    it "is true if the user has opted out globally" do
      expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_out").and_return true
      expect(subject.opt_out?).to be true
    end

    it "is true if the user has set an environment variable" do
      env["CHEF_TELEMETRY_OPT_OUT"] = true
      expect(subject.opt_out?).to be true
    end

    it "is true if the user has opted out locally" do
      expect(File).to receive(:exist?).with("/path/to/cwd/.chef/telemetry_opt_out").and_return true
      expect(subject.opt_out?).to be true
    end

    it "is false if the user has opted in" do
      expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_in").and_return true
      expect(subject.opt_out?).to be false
    end

    it "is true by default" do
      expect(subject.opt_out?).to be true
    end
  end

  describe "#made?" do
    it "is true if the user has opted out globally" do
      expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_in").and_return false
      expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_out").and_return true
      expect(subject.made?).to be true
    end

    it "is true if the user has opted in globally" do
      expect(File).to receive(:exist?).with("/Users/chef_user/.chef/telemetry_opt_in").and_return true
      expect(subject.made?).to be true
    end

    it "is false if the user has not made a decision" do
      expect(subject.made?).to be false
    end
  end
end
