# frozen_string_literal: true

require_relative "config"

module LightBlog
  # Takes care of generating rake tasks through LightBlog.inject_rake_tasks
  class RakeTasksInjector
    attr_reader :config, :rake_context, :namespace, :task_name

    def initialize(config, rake_context, namespace: :article, task_name: :new_article)
      config = Config.new(config) if config.is_a?(Hash)
      @config = config
      @rake_context = rake_context
      @namespace = namespace
      @task_name = task_name
    end

    def inject
      injector = self
      @rake_context.instance_eval do
        namespace injector.namespace do
          desc "Create a new article"
          task injector.task_name do
            injector.ask_for_title_and_create_article
          end
        end
      end
    end

    def ask_for_title_and_create_article
      puts "What is the new article title?"
      title = $stdin.gets.strip
      if title.empty?
        puts "task aborted"
        return
      end
      create_article title
    end

    private

    def create_article(title)
      path, time = path_from_title title
      return unless path

      require "yaml"
      article = { "title" => title, "created_at" => time.strftime(@config.date_format),
                  "updated_at" => nil }.to_yaml
      article << "\nArticle content here."
      File.write path, article
      puts "Crated article at #{path}"
    end

    def path_from_title(title)
      time = Time.now
      slug = slug_from_title title, time
      path = File.join(@config.articles_path, slug) + @config.article_file_extension
      if File.exist?(path)
        puts "Aborting task. File already exists: #{path}"
        return
      end
      [path, time]
    end

    def slug_from_title(title, time)
      # TODO: Improve slug for other languages than English
      [time.strftime("%Y-%m-%d"), title.downcase.gsub(/\W/, "-")].join("-")
    end
  end
end
