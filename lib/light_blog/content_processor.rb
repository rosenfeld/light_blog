# frozen_string_literal: true

require "erubi"

module LightBlog
  # Process ERB articles when config allows it, provides static_path helper.
  # This is useful for setting some image paths and other static assets
  class ContentProcessor
    def initialize(config, content)
      @config = config
      @content = content
    end

    def render
      eval Erubi::Engine.new(@content).src
    rescue StandardError => e
      "<p>Invalid article ERB source: #{e.message}.</p><div><pre>#{e.backtrace.join("\n")}</pre></div>"
    end

    # helpers

    def static_path(path)
      @static_path ||= [@config.base_mount_path, @config.articles_static_mount_path].join
      [@static_path, path].join("/")
    end
  end
end
