class Chef
  class Telemetry
    class Decision

      # Represents a telemetry opt-in made by CLI argument.
      class Argument

        attr_reader :argv

        def initialize(args = ARGV)
          @argv = args
        end

        def enable?
          # If both provided, disable telemetry.
          arg_seek("enable") && !arg_seek("disable")
        end

        def disable?
          arg_seek("disable")
        end

        private

        def arg_seek(what)
          return true if argv.include?("--chef-telemetry=#{what}")

          i = argv.index("--chef-telemetry")
          return false if i.nil?

          val = argv[i + 1]
          !val.nil? && val.downcase == what
        end
      end
    end
  end
end
