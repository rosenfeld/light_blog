# frozen_string_literal: true

require "nokogiri"
require "rack/test"
require "rspec-html-matchers"

RSpec.describe LightBlog::App do
  include Rack::Test::Methods
  include RSpecHtmlMatchers

  let(:config) do
    {
      articles_path: File.join(__dir__, "fixtures", "articles"),
      title: "My Blog",
      base_mount_path: "/blog/"
    }
  end
  let(:articles) do
    [
      ["sample", "My Article Title"],
      ["sample_code", "Blazing Code"],
      ["another_june_article", "Yet Another June Article"]
    ]
  end

  before { @app = nil }

  def app
    @app ||= LightBlog.create_app config
  end

  def silence_errors
    log_errors = app.config.log_errors
    app.config.log_errors = false
    yield
  ensure
    app.config.log_errors = log_errors
  end

  context "when root path is requested (listing)" do
    let(:response) { get "" }

    it "returns status 200 OK" do
      expect(response.status).to be 200
    end

    it "use config.title as the page title" do
      expect(response.body).to include "<title>My Blog</title>"
    end

    it "displays the INDEX link in the sidebar menu" do
      expect(response.body).to include '<a class="pure-menu-heading" href="/blog/">Index</a>'
    end

    it "displays the tags links in the sidebar menu" do
      tags = %w[awesome coding june sample testing]
      tags.each do |tag|
        expect(response.body).to have_tag("aside#menu a.pure-menu-link",
                                          text: tag, href: "/blog/tags/#{tag}")
      end
    end

    it "links to the articles" do
      articles.each do |slug, title|
        expect(response.body).to have_tag("section#main.content a",
                                          text: title, href: "/blog/#{slug}")
      end
    end
  end

  context "when error and not_found default handlers are used" do
    it "displays a Not Found page when address is not found" do
      response = get "inexistent_path"
      expect(response.body).to include "404"
    end

    it "displays an Error page when an error occurs" do
      response = silence_errors { get "raise" }
      expect(response.body).to include "500"
    end
  end

  context "with overriden error and not found handlers" do
    let(:not_found_app) do
      lambda { |app|
        "[#{app.config.title}] not found"
      }
    end

    let(:error_handler_app) do
      lambda { |app, e|
        "[#{app.config.title}] overriden: #{e.message}"
      }
    end

    it "allows the not found handler to be overriden" do
      @app = LightBlog.create_app config.merge(title: "My App",
                                               not_found_app: not_found_app)
      response = get "inexistent_path"
      expect(response.body).to eq "[My App] not found"
    end

    it "allows the error handler to be overriden" do
      @app = LightBlog.create_app config.merge(title: "My App",
                                               error_handler_app: error_handler_app)
      response = silence_errors { get "raise" }
      expect(response.body).to eq "[My App] overriden: error"
    end
  end

  context "when requesting the atom feeds" do
    config = {
      articles_path: File.join(__dir__, "fixtures", "articles"),
      root_url: "https://myblog.site",
      title: "My Blog",
      id: "myblog",
      author: "Noel Rosa"
    }

    response_body = feed = nil
    before(:all) do # rubocop:disable RSpec/BeforeAfterAll
      @app = LightBlog.create_app config
      response_body = get("atom").body
      feed = Nokogiri::XML(response_body)
    end

    it "provides the feeds id" do
      expect(feed.at("> feed > id").content).to eq "myblog"
    end

    it "provides the feeds author" do
      expect(feed.at("> feed > author > name").content).to eq "Noel Rosa"
    end

    it "provides the feeds title" do
      expect(feed.at("> feed > title").content).to eq "My Blog"
    end

    def format_time(time)
      time.strftime("%Y-%m-%dT%H:%M:%S%:z")
    end

    it "provides the feeds last updated date" do
      last_updated = File.mtime(app.config.version_path)
      expect(feed.at("> feed > updated").content).to eq format_time(last_updated)
    end

    it "includes the articles' ids (slugs)" do
      expect(feed.at("> feed > entry > id").content).to eq "sample"
    end

    it "includes the articles' links" do
      expect(feed.at("> feed > entry > link")["href"]).to eq "https://myblog.site/sample"
    end

    it "includes the articles' titles" do
      expect(feed.at("> feed > entry > title").content).to eq "My Article Title"
    end

    it "includes the articles' last updated date" do
      expect(feed.at("> feed > entry > updated").content).to eq "2022-10-10T12:00:00-03:00"
    end

    it "includes the articles' content" do
      article_content = Nokogiri::HTML(feed.at("> feed > entry > content").inner_html)
      expect(article_content.at("p > em").content).to eq "mind-blowing"
    end

    it "includes the articles' summary when available" do
      expect(feed.at("> feed > entry > summary").content).to eq "mind-blowing article"
    end
  end

  context "when filtering by tags" do
    let(:expected_tags) do
      [
        ["/blog/tags/awesome", "awesome"],
        ["/blog/tags/coding", "coding"],
        ["/blog/tags/june", "june"],
        ["/blog/tags/sample", "sample"],
        ["/blog/tags/testing", "testing"]
      ]
    end

    it "lists all tags at /tags" do
      response = Nokogiri::HTML(get("tags").body)
      links = response.css("aside[id=menu] ul > li > a")
                      .map { |link| [link["href"], link.content] }
      expect(links).to eq expected_tags
    end
  end
end
