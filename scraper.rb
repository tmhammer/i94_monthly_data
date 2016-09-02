require './dropbox_client'
require './excel_parser'
require './canada_mexico_parser'
require './region_parser'
#require 'scraperwiki'
require 'pp'
require 'csv'

client = DropboxClientWrapper.new
file_paths = client.get_file_paths

client.download_file('/regions.xlsx')
region_dictionary = RegionParser.parse

data = []
file_paths.each do |path|
  next if path == "/regions.xlsx"
  client.download_file(path)
  path.gsub!('/', '')

  new_data = ExcelParser.parse(path, region_dictionary) if path.match(/\A[0-9]{4}.xls(x){0,1}\z/)
  new_data = CanadaMexicoParser.parse(path) if path == "canada_mexico.xlsx"

  data.concat new_data
end

def write_csv_file(translated_rows)
  CSV.open("i94.csv", "wb") do |csv|
    csv << ["i94_country_or_region", "ntto_groups", "date", "i94_code", "amount"]
    translated_rows.each do |row|
      csv << [row[:i94_country_or_region], row[:ntto_groups].join(';'), row[:date], row[:i94_code], row[:amount]]
    end
  end
end

write_csv_file(data)

# # Write out to the sqlite database using scraperwiki library
#ScraperWiki.save_sqlite([:date, :i94_code, :i94_country, :i94_region], data)