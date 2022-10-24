# frozen_string_literal: true

require "rss"

module LightBlog
  # Render the output for the Atom feed format
  class FeedsRenderer
    attr_reader :config, :base_url

    def render(articles, config, base_url)
      @config = config
      @base_url = base_url
      RSS::Maker.make("atom") do |maker|
        setup_feeds_info maker
        add_articles_to_feed(articles, maker)
      end.to_s
    end

    def setup_feeds_info(maker) # rubocop:disable Metrics/AbcSize
      maker.channel.author = config.author || "Anonymous"
      maker.channel.updated = File.mtime(config.version_path).to_s
      maker.channel.about = config.about if config.about
      maker.channel.title = config.title
      maker.channel.id = config.id || config.title
    end

    def add_articles_to_feed(articles, maker) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      root_url = config.root_url || base_url
      articles.each do |article|
        maker.items.new_item do |item|
          item.link = [root_url, article.path].join
          item.title = article.title
          item.updated = (article.updated_at || article.created_at).to_s
          item.summary = article.summary if article.summary
          item.id = article.slug
          item.content.type = "xhtml"
          item.content.xml = article.processed_content
        end
      end
    end
  end
end
