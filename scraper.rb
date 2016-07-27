require './dropbox_client'
require './excel_parser'
require './canada_mexico_parser'
require 'scraperwiki'

client = DropboxClientWrapper.new
file_paths = client.get_file_paths

data = []
file_paths.each do |path|
  client.download_file(path)
  path.gsub!('/', '')

  new_data = path == 'canada_mexico.xlsx' ? CanadaMexicoParser.parse(path) : ExcelParser.parse(path)

  data.concat new_data
end

# # Write out to the sqlite database using scraperwiki library
ScraperWiki.save_sqlite([:date, :i94_code, :i94_country, :i94_region], data)