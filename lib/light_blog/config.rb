# frozen_string_literal: true

require_relative "../../views/views_path"

module LightBlog
  # Configuration for the Roda app
  class Config
    attr_reader :articles_path, :views_path, :layout, :not_found_app, :error_handler_app,
                :version_path, :watch_for_changes, :articles_glob, :date_format, :rouge_theme,
                :views_static_path, :articles_static_path,
                :views_static_mount_path, :articles_static_mount_path,
                :base_mount_path, :keep_article_path, :allow_erb_processing,
                :id, :title, :author, :about, :disqus_forum, :root_url,
                :google_analytics_tag

    def initialize(options = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @keep_article_path = boolean_option options, :keep_article_path, false
      @allow_erb_processing = boolean_option options, :allow_erb_processing, true
      @articles_path = File.expand_path(options[:articles_path] || "articles")
      @title = options[:title] || "LightBlog"
      @author = options[:author]
      @layout = options[:layout]
      @about = options[:about]
      @not_found_app = options[:not_found_app]
      @error_handler_app = options[:error_handler_app]
      @views_path = options[:views_path] || VIEWS_PATH
      # we use realpath so that symlinks also work and we can detect changes to version with Listen:
      @version_path = File.realpath(options[:version_path] || File.join(articles_path, "version"))
      @watch_for_changes = options[:watch_for_changes]
      @articles_glob = File.join(articles_path, options[:articles_glob] || "**/*.md")
      @date_format = options[:date_format] || "%Y-%m-%d %H:%M"
      @rouge_theme = options[:rouge_theme] || "base16"
      @views_static_path = valid_path(options[:views_static_path] ||
                                      File.join(views_path, "static"))
      @articles_static_path = valid_path(options[:articles_static_path] ||
                                         File.join(articles_path, "static"))
      @views_static_mount_path = options[:views_static_mount_path] || "theme"
      @articles_static_mount_path = options[:articles_static_mount_path] || "static"
      @base_mount_path = options[:base_mount_path] || "/"
      @disqus_forum = options[:disqus_forum]
      @root_url = options[:root_url]
      @google_analytics_tag = options[:google_analytics_tag]

      validate_config!
      watch_for_changes! if @watch_for_changes
    end

    def on_version_update(&block)
      raise "Missing block on on_version_update" unless block_given?

      @on_version_update = block
    end

    def stop_watching_for_changes!
      @listener&.stop
      @listener = nil
    end

    private

    def valid_path(path)
      File.exist?(path) ? path : nil
    end

    def boolean_option(options, option, default_value)
      value = options[option]
      value.nil? ? default_value : value
    end

    class InvalidConfigError < StandardError; end

    def validate_config!
      validate_versions_path_is_readable!
      validate_listen_gem_is_installed! if watch_for_changes
    end

    def validate_versions_path_is_readable!
      File.read(version_path)
    rescue StandardError
      raise InvalidConfigError, "The version file is required to be readable: #{version_path}"
    end

    def validate_listen_gem_is_installed!
      require "listen"
    rescue StandardError
      raise InvalidConfigError, "The 'listen' gem is required for watch_for_changes: true"
    end

    def watch_for_changes!
      (@listener = Listen.to(File.dirname(@version_path)) do |modified, _added, _removed|
        @on_version_update&.call if modified.include? @version_path
      end).start
    end
  end
end
