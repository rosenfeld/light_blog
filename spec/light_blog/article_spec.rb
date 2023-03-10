# frozen_string_literal: true

require_relative "fixtures/articles/path"
require "time"

RSpec.describe LightBlog::Article do
  let(:config) do
    LightBlog::Config.new articles_path: FIXTURE_ARTICLES_PATH
  end
  let(:config_pt_br) do
    LightBlog::Config.new articles_path: FIXTURE_ARTICLES_PATH.sub("articles", "articles2"),
                          date_format: "%d/%m/%Y %H:%M"
  end
  let(:article) do
    described_class.new(config, File.join(config.articles_path, "sample.md"))
  end
  let(:article_pt_br) do
    fn = "pra toda ação há uma reação!.md"
    described_class.new(config_pt_br, File.join(config_pt_br.articles_path, fn))
  end
  let(:article_with_code) do
    described_class.new(config, File.join(config.articles_path, "sample-code.md"))
  end

  it "extracts title, created_at, updated_at and tags from header" do
    # the "inv@lid" tag is ignored
    expect([article.title, article.created_at, article.updated_at, article.tags, article.slug])
      .to eq ["My Article Title", Time.new(2022, 10, 10, 12, 0), nil, %w[sample awesome], "sample"]
  end

  it "transliterate latin chars when extracting the article slug" do
    expect(article_pt_br.slug).to eq "pra_toda_acao_ha_uma_reacao"
  end

  it "uses the date_format setting to parse the dates" do
    expect(article_pt_br.created_at).to eq Time.new(2022, 5, 20, 18, 45)
  end

  it "raises InvalidArticle when title or created_at is missing" do
    # here created_at is using an unexpected date format for this config
    fn = "pra toda ação há uma reação!.md"
    expect do
      described_class.new(config, File.join(config_pt_br.articles_path, fn))
    end.to raise_error described_class::InvalidArticle
  end

  it "processes the article content with Markdown" do
    expect(article.processed_content)
      .to eq "<h1>Take your breath</h1>\n\n<p>This is <em>mind-blowing</em>!</p>\n\n" \
             "<p><img src=\"/static/image.png\" title=\"Some Image\" alt=\"some image\" /></p>\n"
  end

  it "does not process ERB unless process_erb is true in the article header" do
    article = described_class.new(config, File.join(config.articles_path, "sample_no_erb.md"))
    expect(article.processed_content)
      .to eq "<h1>Take your breath</h1>\n\n<p>This is <em>mind-blowing</em>!</p>\n\n" \
             "<p><img src=\"%=%20static_path(%22image.png%22)%20%\" title=\"Some Image\" " \
             "alt=\"some image\" /></p>\n"
  end

  it "highlights source-code" do
    if File.exist?(processed_filename = "#{article_with_code.filename}.html")
      expect(article_with_code.processed_content).to eq File.read(processed_filename)
    else
      File.write processed_filename, article_with_code.processed_content
    end
  end
end
