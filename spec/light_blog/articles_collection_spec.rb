# frozen_string_literal: true

require_relative "fixtures/articles/path"

RSpec.describe LightBlog::ArticlesCollection do
  let(:config) do
    LightBlog::Config.new articles_path: FIXTURE_ARTICLES_PATH
  end
  let(:collection) do
    described_class.new(config)
  end

  it "lists valid articles in collection sorted by created at desc, title" do
    expect(collection.articles.map(&:title))
      .to eq ["My Article Title", "Blazing Code", "Yet Another June Article"]
  end

  it "allows filtering articles by tag" do
    expect(collection.filter("sample").map(&:title))
      .to eq ["My Article Title", "Blazing Code"]
  end

  it "returns all articles when tag passed to filter is empty" do
    expect(collection.filter("")).to be collection.articles
  end

  it "lists all available tags from the collection" do
    expect(collection.tags.to_a.sort).to eq %w[awesome coding june sample testing]
  end
end
