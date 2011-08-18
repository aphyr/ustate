module UState
  class Message
    include Beefcake::Message
    
    optional :ok, :bool, 2
    optional :error, :string, 3
    repeated :states, State, 4
    optional :query, Query, 5

    def encode_with_length
      buffer = ''
      encoded = encode buffer
      "#{[encoded.length].pack('N')}#{encoded}"
    end
  end 
end
