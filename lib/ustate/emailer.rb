module UState
  class Emailer
    require 'net/smtp'

    # Registers self with index.
    # Options:
    #   :host: The SMTP host to connect to. Default 'localhost'
    #   :name: The From name used. Default "ustate".
    #   :from: The From address used: e.g. "ustate@your_domain.com"
    def initialize(index, opts = {})
      @opts = {
        :name => 'ustate',
        :host => 'localhost'
      }.merge opts
      raise ArgumentError, "no from address" unless @opts[:from]

      @tell = {}

      index.on_state_change &method(:receive)
      index.on_state_once &method(:receive)
    end

    # Send an email to address about state.
    def email(address, s)
      # Subject
      subject = "#{s.host} #{s.service} #{s.state}"
      if s.once
        subject << " transient "
      else
        subject << " is "
      end
      subject << s.state

      # Body
      body = "#{subject}: #{s.description}"

      # SMTP message
      message = <<EOF
From: #{@opts[:name]} <#{@opts[:from]}>
To: <#{address}>
Subject: #{subject.gsub("\n", ' ')}

#{body}
EOF

      x = Net::SMTP.start(@opts[:host]) do |smtp|
        puts "Connected to #{smtp.inspect}"
        smtp.send_message message, @opts[:from], address
      end
      p x
    end

    # Dispatch emails to each address which is interested in this state
    def receive(*states)
      state = states.last
      Thread.new do
        @tell.each do |address, q|
          if q === state
            email address, state
          end
        end
      end
    end

    # Notify email when a state matching query_string is
    # received. Multiple calls are ORed together:
    #
    # emailer.tell 'aphyr@aphyr.com', 'state = "error"'
    # emailer.tell 'aphyr@aphyr.com', 'host =~ "frontend%"'
    def tell(email, query_string)
      parser = QueryStringParser.new
      q = parser.parse(query_string)
      unless q
        raise ArgumentError, "error parsing #{query_string.inspect} at line #{parser.failure_line}:#{parser.failure_column}: #{parser.failure_reason}"
      end
      q = q.query

      @tell[email] = if existing = @tell[email]
        Query::Or.new existing, q
      else
        q
      end
    end
  end
end
