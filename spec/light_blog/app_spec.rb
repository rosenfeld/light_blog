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
  let(:app) do
    LightBlog.create_app config
  end
  let(:articles) do
    [
      ["sample", "My Article Title"],
      ["sample_code", "Blazing Code"],
      ["another_june_article", "Yet Another June Article"]
    ]
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
end
