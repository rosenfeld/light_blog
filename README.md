# LightBlog

LightBlog is a Roda app that you can mount on any Rack application, such as Rails, Sinatra or
Roda itself. It doesn't rely on a database and requires minimal resources to run.

Articles are written in Markdown and contain a header specified with the YAML language,
containing its details such as date, title, and tags. They're stored on disk (typically in
a git repository) and no database is used by this application.

It's possible to specify the template for the articles and override the 404 and 500 handlers.

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

Article *content* here.
```

## Options

TODO: describe the available options

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

Bug reports and pull requests are welcome on GitLab at https://gitlab.com/rr.rosas/light\_blog.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
