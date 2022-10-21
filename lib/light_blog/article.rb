# frozen_string_literal: true

require "date"
require "pathname"
require "yaml"
require "rdiscount"
require "rouge"

require_relative "content_processor"

module LightBlog
  # represents an article
  class Article
    attr_reader :config, :title, :created_at, :updated_at, :tags, :yaml, :filename, :slug,
                :process_erb, :path

    def initialize(config, filename)
      @config = config
      @filename = filename
      parse_article!
    end

    def processed_content
      @processed_content ||= process_content
    end

    private

    def parse_article!
      yaml, @content = File.read(filename).split("\n\n", 2)
      extract_header! yaml
      slug = Pathname.new(filename).relative_path_from(config.articles_path)
                     .to_s.sub(/\..*/, "")
      @slug = extract_slug(slug)
      @path = [config.base_mount_path, @slug].join
    end

    def extract_slug(slug)
      if config.keep_article_path
        slug_path = File.dirname(slug)
        slug_name = File.basename(slug).gsub(/\W/, "_")
        slug_path == "." ? slug_name : [slug_path, slug_name].join("/")
      else
        slug.gsub(/\W/, "_")
      end
    end

    class InvalidArticle < StandardError; end

    def extract_header!(yaml)
      @yaml = YAML.safe_load yaml
      @title = @yaml["title"]
      @created_at = parse_date! @yaml["created_at"]
      @updated_at = parse_date! @yaml["updated_at"]
      @tags = filter_valid_tags(@yaml["tags"] || [])
      @process_erb = @yaml["process_erb"] || false

      raise InvalidArticle, "Article must have title and created_at: #{filename}" unless @title && @created_at
    end

    INVALID_TAG_CHAR_REGEX = /[^0-9a-zA-Z\-_]/.freeze
    def filter_valid_tags(tags)
      tags.find_all { |tag| tag !~ INVALID_TAG_CHAR_REGEX }
    end

    def parse_date!(strdate)
      Date.strptime strdate, config.date_format
    rescue StandardError
      nil
    end

    def process_content
      content = if process_erb && config.allow_erb_processing
                  ContentProcessor.new(config, @content).render
                else
                  @content
                end
      RDiscount.new(preprocessed_content(content)).to_html
    end

    def preprocessed_content(content)
      content.gsub(/---/, "&mdash;").gsub(/^@@@ (\w+)\n(.*?)^@@@$/m) do
        highlight_code ::Regexp.last_match(1), ::Regexp.last_match(2)
      end
    end

    def highlight_code(language, source)
      # formatted = CodeRay.scan(source, language).div(line_numbers: :table)
      theme = Rouge::Theme.find(config.rouge_theme)
      formatter = Rouge::Formatters::HTMLInline.new(theme)
      table_formatter = Rouge::Formatters::HTMLLineTable.new(formatter)
      lexer = Rouge::Lexer.find(language) || Rouge::Lexers::PlainText
      formatted = table_formatter.format(lexer.lex(source))
      %(<div class="highlighted-code">#{formatted}</div>)
    end
  end
end
