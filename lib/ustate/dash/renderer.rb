module UState
  class Dash
    helpers do
      include Rack::Utils

      alias_method :h, :escape_html

      # Returns a scalar factor from 0.2 to 1, where 0.2 is "on the order of
      # age_scale ago", and 1 is "very recent"
      def age_fraction(time)
        return 1 if time.nil?

        x = 1 - ((Time.now - time) / Dash.config[:age_scale])
        if x < 0.2
          0.2
        elsif x > 1
          1
        else
          x
        end
      end

      # Finds the longest common prefix of a list of strings.
      # i.e. 'abc, 'ab', 'abdf' => 'ab'
      def longest_common_prefix(strings, prefix = '')
        return strings.first if strings.size <= 1

        first = strings[0][0,1] or return prefix
        tails = strings[1..-1].inject([strings[0][1..-1]]) do |tails, string|
          if string[0,1] != first
            return prefix
          else
            tails << string[1..-1]
          end
        end

        longest_common_prefix(tails, prefix + first)
      end

      # Renders a time to an HTML tag.
      def time(unix)
        t = Time.at(unix)
        "<time datetime=\"#{time.iso8601}\">#{strftime(Dash.config[:strftime])}</time>"
      end

      # Renders a state as the given HTML tag with a % width corresponding to
      # metric / range.
      def state_bar(s, opts = {})
        opts = {tag: 'div', range: 1}.merge opts

        return '' unless s
        x = s.metric

        # Text
        text = case x
        when Float
          '%.2f' % x
        when Integer
          x.to_s
        else
          '?'
        end

        # Size
        size = begin
          (x || 0) * 100 / range
        rescue ZeroDivisionError
          0
        end

        "<#{opts[:tag]} class=\"state #{s.state]}\" style=\"opacity: #{age_fraction s.time}; width: #{size}%\" title=\"#{h s.description}\">#{h text}</#{opts[:tag]}>"
      end

      # Renders a state as a short tag.
      def state_short(s, opts={tag: 'li'})
        if s
          "<#{opts[:tag]} class=\"state #{s.state}\" style=\"opacity: #{age_fraction s.time}\" title=\"#{h s.description}\">#{h s.host} #{h s.service}</#{opts[:tag]}>"
        else
          "<#{opts[:tag]} class=\"service\"></#{opts[:tag]}>"
        end
      end
    end 
  end
end
