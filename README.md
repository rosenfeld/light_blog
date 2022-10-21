# LightBlog

LightBlog is a Roda app that you can mount on any Rack application, such as Rails, Sinatra or Roda
itself. It doesn't rely on a database and requires minimal resources to run.

Articles are written in Markdown and contain a header specified with the YAML language,
containing its details such as date, title, and tags.

It's possible to specify the template for the articles and override the 404 and 500 handlers.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add light_blog

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitLab at https://gitlab.com/rr.rosas/light\_blog.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
