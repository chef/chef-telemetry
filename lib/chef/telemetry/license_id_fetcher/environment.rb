require_relative "base"

class Chef
  class Telemetry
    class LicenseIdFetcher

      # Represents fetching a license ID by environment variables.
      class Environment < Base

        attr_reader :env

        def initialize(env)
          @env = env
        end

        def fetch
          if env["CHEF_LICENSE_ID"]
            if match = env["CHEF_LICENSE_ID"].match(/^#{LICENSE_ID_REGEX}$/)
              return match[1]
            else
              raise LicenseIdNotFetchedError.new("Malformed License ID passed in ENV variable CHEF_LICENSE_ID - should be #{LICENSE_ID_PATTERN_DESC}")
            end
          end
          return nil
        end
      end
    end
  end
end
