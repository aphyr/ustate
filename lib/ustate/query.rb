module UState
  class Query
    include Beefcake::Message
  
    optional :string, :string, 1
  end 
end
