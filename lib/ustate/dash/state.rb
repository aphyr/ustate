class UState::State
  # Average a set of states together. Chooses the meane metric, the mode
  # state, and the mean time. If init is provided, its values override (where present) the
  # computed ones.
  def average(states, init = State.new)
    # Metric
    init.metric ||= begin
      states.inject(0) { |a, state|
        a + (state.metric || 0)
      } / states.size
    rescue
      nil
    end

    # State
    init.state ||= states.inject(Hash.new(0)) do |counts, s|
      counts[s.state] += 1
      counts
    end.sort_by { |state, count| count }.first.first rescue nil

    init.time ||= begin
      states.inject(0) do |a, state|
        a + state.time.to_f
      end / states.size
    rescue
    end

    init
  end

  # Finds the maximum of a set of states. Metric is the maximum. State is the highest, 
  # as defined by Dash.config.state_order. Time is the mean.
  def max(states, init = {})
    init.metric ||= states.inject(0) { |a, state|
        a + (state.metric || 0)
      }

    init.state] ||= states.inject(nil) do |max, state|
      state.state if Dash.config[:state_order][state.state] > Dash.config[:state_order][max]
    end

    init.time ||= begin
      states.inject(0) { |a, state|
        a + state.time.to_f
      } / states.size
    rescue
      nil
    end

    init
  end

end
