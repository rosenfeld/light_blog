# frozen_string_literal: true

require_relative "config"
require "i18n"
require "fileutils"

module LightBlog
  # Takes care of generating rake tasks through LightBlog.inject_rake_tasks
  class RakeTasksInjector
    attr_reader :config, :rake_context, :namespace, :new_article_task_name,
                :generate_views_task_name, :generated_views_path, :new_article_task_only

    def initialize(rake_context, config = {}, # rubocop:disable Metrics/ParameterLists
                   namespace: :article,
                   new_article_task_name: :new_article,
                   generate_views_task_name: :generate_views,
                   generated_views_path: "light_blog_views",
                   new_article_task_only: false)
      config = Config.new(config) if config.is_a?(Hash)
      @config = config
      @rake_context = rake_context
      @namespace = namespace
      @new_article_task_name = new_article_task_name
      @generate_views_task_name = generate_views_task_name
      @generated_views_path = generated_views_path
      @new_article_task_only = new_article_task_only
    end

    def inject # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      injector = self
      @rake_context.instance_eval do
        namespace injector.namespace do
          desc "Create a new article"
          task injector.new_article_task_name do
            injector.ask_for_title_and_create_article
          end

          next if injector.new_article_task_only

          desc "Copy default views to #{injector.generated_views_path}"
          task injector.generate_views_task_name, :force do |_t, args|
            force_arg = args[:force]&.downcase
            force = %w[true yes 1 force].any? { |o| force_arg == o } if force_arg
            injector.copy_views force
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

    # make it easier to view the backtrace when an error occurs
    def inspect
      "LightBlog Task Injector"
    end

    VIEWS_FILES = %w[404.erb 500.erb article.erb index.erb layout.erb tags.erb
                     static/layout.css static/layout-print.css static/menu.css].freeze
    def copy_views(force)
      FileUtils.rm_rf generated_views_path if force
      abort_copy_views! if File.exist?(generated_views_path)
      FileUtils.mkdir_p File.join(generated_views_path, "static")
      copy_views_files File.expand_path "../../views", __dir__
      puts "Default views have been copied to #{generated_views_path}"
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
      version = File.read(@config.version_path).to_i
      File.write @config.version_path, (version + 1).to_s
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
      title_slug = I18n.transliterate(title, replacement: "-").
        downcase.gsub(/\W/, "-").gsub(/--/, "-").gsub(/\A-/, "").gsub(/-\z/, "")
      [time.strftime("%Y-%m-%d"), title_slug].join("-")
    end

    def abort_copy_views!
      puts "#{generate_views_task_name} already exists, aborting. If you want " \
           "to override it, call rake " \
           "#{namespace}:#{generate_views_task_name}[force]"
      exit 1
    end

    def copy_views_files(srcdir)
      VIEWS_FILES.each do |fn|
        FileUtils.cp File.join(srcdir, fn), File.join(generated_views_path, fn)
      end
    end
  end
end
