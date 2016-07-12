require './dropbox_client'
require './excel_parser'
require 'scraperwiki'

client = DropboxClientWrapper.new
file_paths = client.get_file_paths

data = []
file_paths.each do |path|
  client.download_file(path)
  path.gsub!('/', '')
  data.concat ExcelParser.parse(path)
end

# # Write out to the sqlite database using scraperwiki library
ScraperWiki.save_sqlite([:date, :i94_code, :country], data)
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".