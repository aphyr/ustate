module UState
  class Client::Query
    # Little query builder
    def initialize
      @predicate = nil
    end

    def method_missing(field)
      field = field.to_sym
      beefcake_field = UState::Query.fields.find { |f|
        f.name == field
      }
      raise ArgumentError, "no such field #{field.inspect}" unless beefcake_field
      beefcake_field.type::Proxy
    end
  end
end
