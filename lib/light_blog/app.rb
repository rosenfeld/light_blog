# frozen_string_literal: true

require "roda"
require "time"
require_relative "articles_collection"
require_relative "feeds_renderer"

# - Configure error and not_found handlers support
# - asset_path/static_path in markdown article
# - add task to copy default views
# - add task to create new article
# - add atom / feeds support
# - add support for Localization (I18n)
# - add a README
# - add support for Google Analytics
# - add rack/test tests
# - setup circle/ci integration

module LightBlog
  # Base Blog App. Must be subclassed and the config method must be overridden.
  class App < Roda
    class << self
      attr_reader :collection
    end

    plugin :empty_root
    plugin :error_handler
    plugin :not_found

    error do |e|
      # just in case something goes wrong before we setup the final error handler:
      "Oh No!\n\n#{e.message}<br/><br/>\n\n#{e.backtrace.join("<br/>\n")}"
    end

    def self.config
      raise "Not implemented. This class must be subclassed and the config method must be overridden"
    end

    def config
      self.class.config
    end

    def self.refresh_articles(reload_routes: true)
      (@collection = ArticlesCollection.new(config)).refresh!
      setup_routes if reload_routes
    end

    def self.setup # rubocop:disable Metrics/AbcSize
      error { |e| config.error_handler_app.call self, e }
      not_found { config.not_found_app.call self }
      refresh_articles reload_routes: false
      plugin :render, views: config.views_path, escape: true,
                      layout_opts: { locals: { collection: @collection, config: config } }
      plugin :multi_public, public_paths unless public_paths(refresh: true).empty?
      @paths = public_paths.keys
      config.on_version_update { refresh_articles }
      setup_routes
      self
    end

    def self.public_paths(refresh: false)
      @public_paths = nil if refresh
      @public_paths ||=
        { config.views_static_mount_path => config.views_static_path,
          config.articles_static_mount_path => config.articles_static_path }.compact
    end

    def self.setup_routes # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      collection = @collection
      paths = @paths
      route do |r| # rubocop:disable Metrics/BlockLength
        I18n.locale = config.locales.first

        unless paths.empty?
          r.on(paths) do |path|
            r.multi_public path
          end
        end

        r.root do
          view "index", locals: { articles: collection.articles }
        end

        r.get("atom") do
          render_feeds
        end

        r.on("tags") do
          r.root do
            view "tags", locals: { tags: collection.tags }
          end

          collection.tags.each do |tag|
            articles = collection.filter(tag)
            r.on(tag) do
              @tag = tag
              r.root do
                view "index", locals: { articles: articles }
              end

              r.get("atom") do
                render_feeds
              end
            end
          end
          nil
        end

        collection.articles.each do |article|
          r.get(article.slug) do
            view "article", locals: { article: article }
          end
        end

        r.get("raise") { raise "error" } if defined?(::LIGHT_BLOG_RUNNING_TESTS)
        nil
      end
    end

    def format_time(time)
      # TODO: replace with I18n.localize
      time.strftime(config.date_format)
    end

    protected

    def render_feeds
      articles = collection.filter(@tag || "")
      FeedsRenderer.new.render(articles, config, request.base_url)
    end

    def atom_discovery_path
      path = @tag ? "tags/#{@tag}/atom" : "atom"
      [config.base_mount_path, path].join
    end

    def collection
      self.class.collection
    end
  end
end
