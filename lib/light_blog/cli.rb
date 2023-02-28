# frozen_string_literal: true

require "optparse"
options = {}
args = OptionParser.new do |parser|
  parser.banner = "Usage: light_blog new myblog [options]"
  parser.on("-G", "--skip-git", "Skip Git integration"){ options[:skip_git] = true }
  parser.on("-v", "--verbose", "Verbose mode"){ options[:verbose] = true }
  parser.on("-q", "--quiet", "Quiet mode"){ options[:quiet] = true }
end.parse!

command = args.shift
unless command == "new"
  puts "Unsupported command: #{args.join " "}. Type light_blog -h for usage instructions."
  exit 1
end

unless args.size == 1
  puts "light_blog new expects a single argument. '#{args.join " "}' is not a valid argument. " \
    "Type light_blog -h for usage instructions."
  exit 1
end

target_dir = args.shift

if File.exist? target_dir
  puts "Directory #{target_dir} already exists. Aborting."
  exit 1
end

Dir.mkdir target_dir
init_script = "
bundle init
bundle add light_blog puma rake listen
bundle binstubs puma rake
"

rakefile = %q{
require "light_blog"

LightBlog.inject_rake_tasks self
}.strip

config_ru = %Q{
require "light_blog"

run LightBlog.create_app
}.strip

require "tempfile"

Dir.chdir target_dir do
  verbose_option = options[:verbose] ? "" : "2>/dev/null"
  `git init #{verbose_option}` unless options[:skip_git]
  Tempfile.create("create_light_blog") do |file|
    file.write init_script
    file.close
    verbose = options[:verbose] ? "-x" : ""
    run = ->{ `/bin/bash #{verbose} #{file.path}` }
    bundler_loaded = false
    begin
      Bundler.with_unbundled_env{ bundler_loaded = true; run[] }
    rescue
      run[] unless bundler_loaded
    end
  end
  File.write "Rakefile", rakefile
  File.write "config.ru", config_ru
end

instructions = "Type:\n\ncd #{target_dir}\nbin/rake article:new_article\nbin/puma -p 3000"
puts instructions unless options[:quiet]

require "fileutils"

