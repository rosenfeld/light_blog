# LightBlog

LightBlog is a Roda app that you can mount on any Rack application, such as Rails, Sinatra or
Roda itself. It doesn't rely on a database and requires minimal resources to run.

Articles are written in Markdown and contain a header specified with the YAML language,
containing its details such as date, title, and tags. They're stored on disk (typically in
a git repository) and no database is used by this application.

It's possible to specify the template for the articles and override the 404 and 500 handlers.

Comments are disabled by default but are supported out-of-the-box with
[Disqus](https://disqus.com/) if you provide your Disqus id in the options. This is also valid
for Google Analytics integration.

Atom feeds are supported out-of-the-box.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add light_blog

In order to allow the app to watch for changes, also add the listen gem:

    $ bundle add listen

## Usage

Create a config.ru file like this:

```ruby
# config.ru
require "light_blog"

run LightBlog.create_app
```

Optionally, create a Rakefile like this, if you want to be able to generate new articles
(or you can simply type them without a generator if you prefer):

```ruby
# Rakefile
require "light_blog"

LightBlog.inject_rake_tasks self
```

Generate a new file with this rake command:

    $ bundle exec rake article:new_article

Type the title of the article and you can finally edit the generated article.

Then run the application (I'll use puma as an example):

    $ bundle add puma
    $ bundle exec puma -p 4000

Then simply navigate to [http://localhost:4000](http://localhost:4000) to see your article
listed there. If you add tags to your article, the tags will be displayed in the left menu.

Sample article example:

```markdown
---
title: LightBlog is Great!
created_at: 2023-02-16 17:26
updated_at:
tags: ["blog", "ruby"]
process_erb: true

Article *content* here.

![awesome picture](<%= static_path("awesome.png") %> "Awesome Picture")
```

## Integrating LightBlog with an existent website

If you want to integrate the blog to an existing site, there are 2 easy options you might want
to consider:

* mount this Rack app on top of yours, if the main site is also written as a Rack-based app
(such as Rails, Roda, Sinatra, whatever);
* use a reverse proxy to do that for you (you could mount it on the /blog/ path for example or
serve it in its own subdomain such as blog.myapp.com);

The latter option would be safer as any vulnerabilities on either app wouldn't affect the other.

Just be aware of the `root_url`, `base_mount_path`, `views_static_mount_path` and
`articles_static_mount_path` options.

## Options

LightBlog accept many options that allow you to customize it a lot:

```ruby
LightBlog.create_app(
  # default options:
  title: "LightBlog",
  id: nil, # used by the Atom feeds generation, title is used if id is nil
  author: nil, # used by the Atom feeds generation,
  about: nil, # used by the Atom feeds generation,
  articles_path: "./articles",
  views_path: LightBlog::VIEWS_PATH,
  not_found_app: ->(app) { app.render "404" },
  error_handler_app: lambda {|app, e|
    puts "Error: #{e.message}\n\n#{e.backtrace.join("<br/>\n")}" if log_errors
    app.render "500"
  },
  watch_for_changes: true, # false if the listen gem is not available
  # when watch_for_changes is true, updating this file will refresh the articles collection:
  version_path: "#{articles_path}/version",
  article_file_extension: ".md",
  articles_glob: "**/*#{article_file_extension}",
  date_format: "%Y-%m-%d %H:%M",
  rouge_theme: "base16", # rouge code highlighter theme
  views_static_path: "#{views_path}/static", # static assets used in views
  articles_static_path: "#{articles_path}/static", # static assets used in articles
  views_static_mount_path: "theme", # files are served through /theme/file-path
  articles_static_mount_path: "static",
  base_mount_path: "/", # base path for the LightBlog app
  disqus_forum: nil, # use your Disqus id to enable comments
  google_analytics_tag: nil, # use your GA tag in order to integrate with Google Analytics
  # auto-detect root_url by default.
  # Used to generate the full link to the articles in the Atom feeds:
  root_url: nil,
  locales: [:en], # specify which languages to support. LightBlog uses the i18n gem
  i18n_load_path: [], # specify where the locale YAML files are located
  i18n_fallback_to_en: true, # should the app use the English locale when translation is missing?
  # should LightBlog automatically create the articles store if it doesn't exist?
  create_articles_store_if_missing: true
)
```

The Rake tasks injector also accept some options:

```ruby
LightBlog.inject_rake_tasks(
  date_format:  "%Y-%m-%d %H:%M",
  articles_path: "articles",
  version_path: "#{articles_path}/version",
  article_file_extension: ".md",
  namespace: :article,
  new_article_task_name: :new_article,
  generate_views_task_name: :generate_views,
  generated_views_path: "light_blog_views",
  new_article_task_only: false # should only the new_article task be supported?
)
```


## Deployment

It's recommended to serve the blog behind a reverse proxy such as Nginx. Besides the usual
benefits of proxying your app, nginx could help you with:

* properly dealing with caching the pages;
* protecting against DoS and DDoS;
* enabling HTTPS;

None of those features are offered by `light_blog` out-of-the-box.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to
run the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## History

This blog app is heavily inspired on [Toto](https://github.com/cloudhead/toto). Many thanks to
its author for the idea of storing the articles directly in a git repository rather than using
a database.

I never actually used Toto myself. I read an article about it once, and loved the idea. But I
implemented a Rails app at that time that would borrow the same idea when building my site.
When Heroku decided they would no longer offer the free tier, I decided to rewrite my site,
since it was running a very old Rails version.

I haven't used Rails for the past few years, so I decided to rewrite it with
[Roda](https://github.com/jeremyevans/roda) from Jeremy Evans, the same author of
[Sequel](https://sequel.jeremyevans.net/).

While doing so, I thought it might be a good idea to separate the blog part from the rest of my
site and eventually open-source this part, which happened in February 2023. I store my articles
in a separate repository, so that you're free to use this app as is with your own articles
or to mount it in your own application, as I did in my own homepage.

Enjoy!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rosenfeld/light_blog.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
