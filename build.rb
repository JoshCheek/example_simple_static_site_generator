# This ships in Ruby's stdlib
require 'erb'
require 'yaml'

# Helper methods that we can call in the templates
def self.link(page)
  <<~HTML
    <a href="#{page[:path]}">#{page[:name]}</a>
  HTML
end

# Make the root dir the CWD so we can use relative paths without breaking things
Dir.chdir __dir__

# We'll write the statically generated site here
Dir.mkdir 'dist' unless Dir.exist? 'dist'

# Parse the pages to get their basic info
@pages = Dir['src/*'].map do |in_path|
  path = in_path.sub('src/', '').chomp('.erb')
  out_path = "dist/#{path}"
  metadata_yaml, erb = File.read(in_path).split("---\n", 2)
  YAML.safe_load(metadata_yaml).transform_keys(&:to_sym).merge(
    in_path: in_path, out_path: out_path, path: path, erb: erb
  )
end

# Set any variables (so we can refer to a page by name)
@pages.each do |page|
  next unless page[:variable]
  instance_variable_set page[:variable], page
end

# Render the pages
@pages.each do |page|
  html = ERB.new(page[:erb], trim_mode: '>').result(TOPLEVEL_BINDING)
  File.write page[:out_path], html
end
