class Chef
  class Telemetry
    class Decision

      # Represents a telemetry opt-in made by environment variables.
      class Environment

        attr_reader :env

        def initialize(env)
          @env = env
        end

        def opt_in?
          env_seek("opt-in")
        end

        def opt_out?
          env_seek("opt-out")
        end

        def opt_in_no_persist?
          env_seek("opt-in-no-persist")
        end

        def opt_out_no_persist?
          env_seek("opt-out-no-persist")
        end

        private

        def env_seek(what)
          if env["CHEF_TELEMETRY"] && env["CHEF_TELEMETRY"].downcase == what
            return true
          end
          false
        end
      end
    end
  end
end
