begin
  require "thor"
rescue
  raise "Must have thor gem installed to use this mixin"
end

module Chef::Telemetry
  module CLIFlags
    module Thor
      def self.included(klass)
        klass.class_option :chef_telemetry,
          type: :string,
          desc: "Enable or disable anonymous usage data collection for this invocaction: enable, disable"
      end
    end
  end
end
