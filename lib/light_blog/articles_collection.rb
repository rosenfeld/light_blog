# frozen_string_literal: true

require "set"
require_relative "article"

module LightBlog
  # collection of articles
  class ArticlesCollection
    attr_reader :config, :articles, :tags

    def initialize(config)
      @articles = []
      @tags = Set.new
      @config = config
      refresh!
    end

    def sorted_tags
      tags.to_a.sort
    end

    def refresh!
      @article_by_slug = {}
      @tags = Set.new
      @articles = find_articles.sort_by do |article|
        [-article.created_at.to_time.to_i, article.title]
      end
    end

    def filter(tag = "")
      return @articles if tag.empty?

      @articles.find_all { |a| a.tags.include?(tag) }
    end

    private

    def find_articles
      articles = []
      Dir[config.articles_glob].each do |fn|
        articles << (article = Article.new(config, fn))
        @article_by_slug[article.slug] = article
        @tags |= article.tags
      rescue StandardError => e
        puts "Could not process article at #{fn}: #{e.message}\n\n#{e.backtrace.join("\n")}"
        next
      end
      articles
    end
  end
end
