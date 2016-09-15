require './dropbox_client'
require './excel_parser'
require './canada_mexico_parser'
require './region_parser'
require './visa_type_parser'
require 'scraperwiki'
require 'pp'
require 'csv'

def main
  client = DropboxClientWrapper.new
  file_paths = client.get_file_paths('/')

  client.download_file('/regions.xlsx')
  region_dictionary = RegionParser.parse
  visa_type_dictionary = build_visa_type_dictionary(client)

  data = []
  file_paths.each do |path|
    next if (path == "/regions.xlsx" || path == "/visa_type")
    client.download_file(path)
    path.gsub!('/', '')

    new_data = ExcelParser.parse(path, region_dictionary) if path.match(/\A[0-9]{4}.xls(x){0,1}\z/)
    new_data = CanadaMexicoParser.parse(path) if path == "canada_mexico.xlsx"

    data.concat new_data
    File.delete(path)
  end

  data.each { |entry| add_visa_type_fields(entry, visa_type_dictionary) }

  #write_csv_file(data)

  # # Write out to the sqlite database using scraperwiki library
  ScraperWiki.save_sqlite([:date, :i94_code, :i94_country, :i94_region], data)
end

def add_visa_type_fields(entry, visa_type_hash)
  if visa_type_hash.key?(entry[:i94_country_or_region]) && visa_type_hash[entry[:i94_country_or_region]].key?(entry[:date])
      entry.merge!(visa_type_hash[entry[:i94_country_or_region]][entry[:date]])
  else
    entry.merge!({business_visa_amount: "", pleasure_visa_amount: "", student_visa_amount: ""})
  end
end

def write_csv_file(translated_rows)
  CSV.open("i94.csv", "wb") do |csv|
    csv << ["i94_country_or_region", "ntto_groups", "date", "i94_code", "total_amount", "business_visa_amount", "pleasure_visa_amount", "student_visa_amount"]
    translated_rows.each do |row|
      csv << [row[:i94_country_or_region], row[:ntto_groups].join(';'), row[:date], row[:i94_code], row[:total_amount], row[:business_visa_amount], row[:pleasure_visa_amount], row[:student_visa_amount]]
    end
  end
end

def build_visa_type_dictionary(client)
  file_paths = get_visa_type_file_paths(client).each 
  visa_type_hash = {}
  file_paths.each do |path|
    client.download_file(path)
    path.gsub!('/', '')

    visa_type_hash = merge_recursively(visa_type_hash, VisaTypeParser.parse(path))

    File.delete(path)
  end
  visa_type_hash
end

def get_visa_type_file_paths(client)
  year_paths = client.get_file_paths('/visa_type')
  file_paths = []
  year_paths.each do |pos|
    file_paths.concat client.get_file_paths(pos)
  end
  file_paths
end

def merge_recursively(a, b)
  a.merge(b) {|key, a_item, b_item| merge_recursively(a_item, b_item) }
end

main