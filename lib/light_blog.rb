# frozen_string_literal: true

require_relative "light_blog/version"
require_relative "light_blog/config"
require_relative "light_blog/app"

# A simple Blog app, that doesn't rely on a database
module LightBlog
  class Error < StandardError; end

  def self.create_app(config = {})
    cfg = Config.new(config)

    Class.new(App) do
      define_singleton_method(:config) { cfg }
    end.setup
  end

  def self.inject_rake_tasks(rake_context, config = {},
                             namespace: :article, task_name: :new_article)
    require_relative "light_blog/rake_tasks_injector"
    RakeTasksInjector.new(rake_context, config, namespace: namespace, task_name: task_name).inject
  end
end
