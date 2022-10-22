require "rouge"

module LightBlog
  class RougeFormatter < Rouge::Formatter
    tag 'my_formatter'
    def initialize(formatter, opts={})
      @formatter = formatter
    end

    def stream(tokens, &b)
      buffer = [%(<table style="font-family: monospace"><tbody>)]
      token_lines(tokens).with_index(1) do |line_tokens, lineno|
        buffer << %(<tr>)
        buffer << %(<td )
        buffer << %(style="-moz-user-select: none;-ms-user-select: none;)
        buffer << %(-webkit-user-select: none;user-select: none;">)
        buffer << %(#{lineno}</td>)
        buffer << %(<td style="white-space: pre">)
        @formatter.stream(line_tokens) { |formatted| buffer << formatted }
        buffer << "\n</td></tr>"
      end
      buffer << %(</tbody></table>)
      yield buffer.join
    end
  end
end
