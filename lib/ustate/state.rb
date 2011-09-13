module UState
  class State
    include Beefcake::Message
    
    optional :time, :int64, 1 
    optional :state, :string,  2
    optional :service, :string, 3
    optional :host, :string, 4
    optional :description, :string, 5
    optional :once, :bool, 6
    optional :metric_f, :float, 15

    # Average a set of states together. Chooses the mean metric, the mode
    # state, mode service, and the mean time. If init is provided, its values
    # override (where present) the computed ones.
    def self.average(states, init = State.new)
      init = case init
             when State
               init.dup
             else
               State.new init
             end
      
      # Metric
      init.metric_f ||= states.inject(0.0) { |a, state|
          a + (state.metric || 0)
        } / states.size
      if init.metric_f.nan?
        init.metric_f = 0.0
      end

      # State
      init.state ||= mode states.map(&:state)
      init.service ||= mode states.map(&:service)

      # Time
      init.time ||= begin
        (states.inject(0) do |a, state|
          a + state.time.to_f
        end / states.size).to_i
      rescue
      end
      init.time ||= Time.now.to_i

      init
    end

    # Sum a set of states together. Adds metrics, takes the mode state, mode
    # service and the mean time. If init is provided, its values override
    # (where present) the computed ones.
    def self.sum(states, init = State.new)
      init = case init
             when State
               init.dup
             else
               State.new init
             end
      
      # Metric
      init.metric_f ||= states.inject(0.0) { |a, state|
          a + (state.metric || 0)
        }
      if init.metric_f.nan?
        init.metric_f = 0.0
      end

      # State
      init.state ||= mode states.map(&:state)
      init.service ||= mode states.map(&:service)

      # Time
      init.time ||= begin
        (states.inject(0) do |a, state|
          a + state.time.to_f
        end / states.size).to_i
      rescue 
      end
      init.time ||= Time.now.to_i

      init
    end
    
    # Finds the maximum of a set of states. Metric is the maximum. State is the
    # highest, as defined by Dash.config.state_order. Time is the mean.
    def self.max(states, init = State.new)
      init = case init
             when State
               init.dup
             else
               State.new init
             end
      
      # Metric
      init.metric_f ||= states.inject(0.0) { |a, state|
          a + (state.metric || 0)
        }
      if init.metric_f.nan?
        init.metric_f = 0.0
      end

      # State
      init.state ||= states.inject(nil) do |max, state|
        state.state if Dash.config[:state_order][state.state] > Dash.config[:state_order][max]
      end

      # Time
      init.time ||= begin
        (states.inject(0) { |a, state|
          a + state.time.to_f
        } / states.size).to_i
      rescue
      end
      init.time ||= Time.now.to_i

      init
    end
    
    def self.mode(array)
      array.inject(Hash.new(0)) do |counts, e|
        counts[e] += 1
        counts
      end.sort_by { |e, count| count }.last.first rescue nil
    end

    # Partition a list of states by a field
    # Returns a hash of field_value => state
    def self.partition(states, field)
      states.inject(Hash.new { [] }) do |p, state|
        p[state.send(field)] << state
      end
    end

    # Sorts states by a field. nil values first.
    def self.sort(states, field)
      states.sort do |a, b|
        a = a.send field
        b = b.send field
        if a.nil?
          -1
        elsif b.nil?
          1
        else
          a <=> b
        end
      end
    end

    def metric
      @metric || metric_f
    end

    def metric=(m)
      @metric = m
    end
  end
end
