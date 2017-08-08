# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      class Version
        MAJOR = 0
        MINOR = 1
        PATCH = 0
        CLASSIFIER = nil
        PRERELEASE_NUMBER = nil
        CHUNKS = [MAJOR, MINOR, PATCH, CLASSIFIER, PRERELEASE_NUMBER].freeze
        VERSION = CHUNKS.reject(&:nil?).join('.').freeze
      end
    end
  end
end
