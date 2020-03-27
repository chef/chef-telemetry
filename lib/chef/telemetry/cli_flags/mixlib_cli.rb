begin
  require "mixlib/cli"
rescue
  raise "Must have mixlib-cli gem installed to use this mixin"
end

module Chef::Telemetry
  module CLIFlags
    module MixlibCLI
      def self.included(klass)
        klass.option :chef_telemetry,
          long: "--chef-telemetry DECISION",
          description: "Enable or disable anonymous usage data collection for this invocaction: enable, disable",
          required: false
      end

    end

  end
end
