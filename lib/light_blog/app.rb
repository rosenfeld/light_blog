# frozen_string_literal: true

require "roda"
require_relative "articles_collection"

# - Configure error and not_found handlers support
# - asset_path/static_path in markdown article
# - add default views
# - add task to copy default views
# - add task to create new article
# - add atom / feeds support
# - add support for Localization (I18n)
# - add a README
# - add support for Google Analytics

module LightBlog
  # Base Blog App. Must be subclassed and the config method must be overridden.
  class App < Roda
    # class << self
    # attr_reader :collection, :paths
    # end

    plugin :empty_root
    plugin :error_handler

    error do |e|
      "Oh No!\n\n#{e.message}<br/><br/>\n\n#{e.backtrace.join("<br/>\n")}"
    end

    def self.config
      raise "Not implemented. This class must be subclassed and the config method must be overridden"
    end

    def self.refresh_articles(reload_routes: true)
      (@collection = ArticlesCollection.new(config)).refresh!
      setup_routes if reload_routes
    end

    def self.setup
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

    def config
      self.class.config
    end

    def self.setup_routes # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      collection = @collection
      paths = @paths
      route do |r|
        r.on(paths) { |path| r.multi_public path } unless paths.empty?

        r.root do
          view "index", locals: { articles: collection.articles }
        end

        r.on("tags") do
          r.root do
            view "tags", locals: { tags: collection.tags }
          end

          collection.tags.each do |tag|
            articles = collection.filter(tag)
            r.get(tag) do
              view "index", locals: { articles: articles }
            end
          end
          nil
        end

        collection.articles.each do |article|
          r.get(article.slug) do
            view "article", locals: { article: article }
          end
        end
        nil
      end
    end
  end
end
