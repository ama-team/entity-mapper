# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      module Aux
        # :nocov:
        # I just did copy-paste from SO
        # https://stackoverflow.com/a/8681953/2908793
        #
        # This class is required to use logger without any real output backend,
        # which is by default
        class NullStream
          INSTANCE = new

          def write(message, *)
            message.size
          end

          def close(*); end

          def <<(*)
            self
          end
        end
        # :nocov:
      end
    end
  end
end
