require 'annotator/initial_description/base'
Dir[File.dirname(__FILE__) + '/initial_description/*.rb'].each {|file| require file }

module Annotator
  module InitialDescription

    NO_DESCRIPTION_COLUMNS = %w{email name title body}

    # Get initial description for given model & column
    def self.for(model, column)
      # Check if any module provides such description
      Base.providers.each do |klass|
        provider = klass.new model, column
        return provider.text if provider.check
      end
    end

  end
end
