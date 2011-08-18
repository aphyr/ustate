require 'rack'
require 'sinatra/base'

module UState
  class Dash < Sinatra::Base
    # A little dashboard sinatra application.
    
    def self.config
      {
        client: {},
        age_scale: 60 * 30,
        state_order: {
          'critical': 3,
          'warning': 2,
          'ok': 1
        }
        strftime: '%H:%M:%S'
      }
    end

    def self.client
      @client ||= UState::Client.new(config[:client])
    end

        
  end
end
