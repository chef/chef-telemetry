require_relative "base"

class Chef
  class Telemetry
    class LicenseIdFetcher

      # Represents getting a license ID by CLI argument
      class Argument < Base

        attr_reader :argv

        def initialize(args = ARGV)
          @argv = args
        end

        def fetch
          # TODO: this only handles explicit equals
          # TODO: WhyTF are we hand-rolling an option parser
          arg = argv.detect { |a| a.start_with? "--chef-license-id=" }
          return nil unless arg
          match = arg.match(/--chef-license-id=#{LICENSE_ID_REGEX}/)
          unless match
            raise LicenseIdNotFetchedError.new("Malformed License ID passed on command line - should be #{LICENSE_ID_PATTERN_DESC}")
          end
          return match[1]
        end
      end
    end
  end
end
