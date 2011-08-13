class UState::State
  include Beefcake::Message
  
  optional :time, :string, 1
  optional :state, :string,  2
  optional :service, :string, 3
  optional :host, :string, 4
  optional :description, :string, 5 
  optional :metric_f, :float, 15 
end
