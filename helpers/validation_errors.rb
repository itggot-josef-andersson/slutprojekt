module DataMapper
  module Validations

    class ValidationErrors

      def to_h
        error_hash = {}
        errors.each_pair do |key, value|
          error_hash[key] = value
        end
        return error_hash
      end

    end

  end
end

