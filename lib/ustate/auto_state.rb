module UState
  class AutoState
    # Binds together a State and a Client. Any change made here
    # sends the state to the client. Useful when updates to a state are made
    # decoherently, e.g. across many methods. Combine with MetricThread (or
    # just Thread.new { loop { autostate.flush; sleep n } }) to ensure regular
    # updates.
    #
    # example:
    #
    # class Job
    #   def initialize
    #     @state = AutoState.new
    #     @state.service = 'job'
    #     @state.state = 'starting up'
    #
    #     run
    #   end
    #
    #   def run
    #     loop do
    #       begin
    #         a
    #         b
    #       rescue Exception => e
    #         @state.once(
    #           state: 'error',
    #           description: e.to_s
    #         )
    #       end
    #     end
    #   end
    #
    #   def a
    #     @state.state = 'heavy lifting a'
    #     ...
    #   end
    #
    #   def b
    #     @state.state = 'heavy lifting b'
    #     ...
    #   end
    
    def initialize(client = Client.new, state = State.new)
      @client = client
      @state = case state
               when State
                 state
               else
                 State.new state
               end
    end

    def description=(description)
      @state.description = description
      flush
    end

    def description
      @state.description
    end

    # Send state to client
    def flush
      @client << @state
    end

    def host=(host)
      @state.host = host
      flush
    end

    def host
      @state.host
    end

    def metric_f=(metric_f)
      @state.metric_f = metric_f
      flush
    end

    def metric_f
      @state.metric_f
    end

    # Issues an immediate update of the state with the :once option
    # set, but does not update the local state. Useful for transient errors.
    # Opts are merged with the state.
    def once(opts)
      o = @state.dup
      opts.each do |k, v|
        o.send "#{k}=", v
      end
      o.once = true
      @client << o
    end

    def state=(state)
      @state.state = state
      flush
    end

    def state
      @state.state
    end

    def service=(service)
      @state.service = service
      flush
    end 

    def service
      @state.service
    end
  end
end
