# frozen_string_literal: true

require "rack/test"
require "rspec-html-matchers"

RSpec.describe LightBlog::App do
  include Rack::Test::Methods
  include RSpecHtmlMatchers

  let(:config) do
    {
      articles_path: File.join(__dir__, "fixtures", "articles"),
      title: "My Blog",
      base_mount_path: "/articles/"
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

  context "when root path is requested (listing)" do
    let(:response) { get "" }

    it "returns status 200 OK" do
      expect(response.status).to be 200
    end

    it "use config.title as the page title" do
      expect(response.body).to include "<title>My Blog</title>"
    end

    it "displays the INDEX link in the sidebar menu" do
      expect(response.body).to include '<a class="pure-menu-heading" href="/articles/">Index</a>'
    end

    it "displays the tags links in the sidebar menu" do
      tags = %w[awesome coding june sample testing]
      tags.each do |tag|
        expect(response.body).to have_tag("aside#menu a.pure-menu-link",
                                          text: tag, href: "/articles/tags/#{tag}")
      end
    end

    it "links to the articles" do
      articles.each do |slug, title|
        expect(response.body).to have_tag("section#main.content a",
                                          text: title, href: "/articles/#{slug}")
      end
    end
  end

  context "when error and not_found default handlers are used" do
    it "displays a Not Found page when address is not found" do
      response = get "inexistent_path"
      expect(response.body).to include "404"
    end

    it "displays an Error page when an error occurs" do
      app.config.log_errors = false
      response = get "raise"
      app.config.log_errors = true
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
      app.config.log_errors = false
      response = get "raise"
      app.config.log_errors = true
      expect(response.body).to eq "[My App] overriden: error"
    end
  end
end
