class Chef
  class Telemetry
    class LicenseIdFetcher
      class Base
        # TODO: get the correct regex, it's not really 8 digits
        LICENSE_ID_REGEX="(\d{8})".freeze
        LICENSE_ID_PATTERN_DESC="eight digits".freeze
      end
    end
  end
end
