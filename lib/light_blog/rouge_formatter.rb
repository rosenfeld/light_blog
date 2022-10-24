# frozen_string_literal: true

require "rouge"

module LightBlog
  # inspired by HTMLLineTable formatter, but uses white-space:pre on td, instead of <pre>
  # The pre tag should contain only text, not other span tags
  class RougeFormatter < Rouge::Formatter
    tag "my_formatter"
    def initialize(formatter, _opts = {}) # rubocop:disable Lint/MissingSuper
      @formatter = formatter
    end

    def stream(tokens)
      buffer = ['<table style="font-family: monospace"><tbody>']
      token_lines(tokens).with_index(1) do |line_tokens, lineno|
        buffer << ("<tr><td style=\"-moz-user-select: none;-ms-user-select: none;" \
          "-webkit-user-select: none;user-select: none;\">#{lineno}</td>" \
          "<td style=\"white-space: pre\">")
        @formatter.stream(line_tokens) { |formatted| buffer << formatted }
        buffer << "\n</td></tr>"
      end
      buffer << "</tbody></table>"
      yield buffer.join
    end
  end
end
