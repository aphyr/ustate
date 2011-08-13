module UState
  class Server::Index
    # Combines state messages. Responds to queries for particular states.
    # Forwards messages to various receivers.
    
    def <<(state)
      puts state
    end
  end
end
