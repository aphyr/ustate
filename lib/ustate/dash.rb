require 'sinatra/base'

module UState
  class Dash < Sinatra::Base
    # A little dashboard sinatra application.
    
    require 'yaml'
    require 'find'
    require 'ustate/client'
    require 'erubis'
    require 'sass'
    
    def self.config
      @config ||= {
        client: {},
        age_scale: 60 * 30,
        state_order: {
          'critical' => 3,
          'warning' => 2,
          'ok' => 1
        },
        strftime: '%H:%M:%S',
        controllers: [File.join(File.dirname(__FILE__), 'dash', 'controller')],
        helpers: [File.join(File.dirname(__FILE__), 'dash', 'helper')],
        views: 'views'
      }
    end

    def self.client
      @client ||= UState::Client.new(config[:client])
    end

    def self.load
      load_config
      config[:controllers].each { |d| load_controllers d }
      config[:helpers].each { |d| load_helpers d }
      set :views, File.expand_path(config[:views])
    end

    # Executes the configuration file.
    def self.load_config
      instance_eval File.read('config.rb')
    end

    # Load controllers.
    # Controllers can be regular old one-file-per-class, but if you prefer a little
    # more modularity, this method will allow you to define all controller methods
    # in their own files.  For example, get "/posts/*/edit" can live in
    # controller/posts/_/edit.rb. The sorting system provided here requires
    # files in the correct order to handle wildcards appropriately.
    def self.load_controllers(dir)
      rbs = []
      Find.find(
        File.expand_path(dir)
      ) do |path|
        rbs << path if path =~ /\.rb$/
      end

      # Sort paths with _ last, becase those are wildcards.
      rbs.sort! do |a, b|
        as = a.split File::SEPARATOR
        bs = b.split File::SEPARATOR

        # Compare common subpaths
        l = [as.size, bs.size].min
        catch :x do
          (0...l).each do |i|
            a, b = as[i], bs[i]
            if a[/^_/] and not b[/^_/]
              throw :x, 1
            elsif b[/^_/] and not a[/^_/]
              throw :x, -1
            elsif ord = (a <=> b) and ord != 0
              throw :x, ord
            end
          end

          # All subpaths are identical; sort longest first
          if as.size > bs.size
            throw :x, -1
          elsif as.size < bs.size
            throw :x, -1
          else
            throw :x, 0
          end
        end
      end

      rbs.each do |r|
        require r
      end 
    end 

    # Load helpers
    def self.load_helpers(dir)
      Find.find(
        File.expand_path(dir)
      ) do |path|
        require path if path =~ /\.rb$/
      end
    end

    # Add an additional public directory.
    def self.public(dir)
      require 'ustate/dash/rack/static'
      use UState::Dash::Rack::Static, :root => dir
    end

    def client
      self.class.client
    end

    def query(*a)
      self.class.client.query(*a).states || []
    end
  end
end
