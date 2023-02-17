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

  def self.inject_rake_tasks(rake_context, config = {}, # rubocop:disable Metrics/ParameterLists
                             namespace: :article, new_article_task_name: :new_article,
                             generate_views_task_name: :generate_views,
                             generated_views_path: "light_blog_views",
                             new_article_task_only: false)
    require_relative "light_blog/rake_tasks_injector"
    RakeTasksInjector.new(rake_context, config, namespace: namespace,
                                                new_article_task_name: new_article_task_name,
                                                generate_views_task_name: generate_views_task_name,
                                                generated_views_path: generated_views_path,
                                                new_article_task_only: new_article_task_only).inject
  end
end
