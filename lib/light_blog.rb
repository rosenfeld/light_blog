# frozen_string_literal: true

require_relative "light_blog/version"
require_relative "light_blog/config"
require_relative "light_blog/app"

# A simple Blog app, that doesn't rely on a database
module LightBlog
  class Error < StandardError; end

  def self.create_app(config)
    raise ":articles_path is mandatory" unless config.include?(:articles_path)

    cfg = Config.new(config)

    Class.new(App) do
      define_singleton_method(:config) { cfg }
    end.setup
  end
end
