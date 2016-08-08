require 'roo' 
require 'roo-xls'          
require 'open-uri'

class ExcelParser

  REGIONS = [
    'WESTERN EUROPE',
    'EASTERN EUROPE',
    'ASIA',
    'MIDDLE EAST',
    'AFRICA',
    'OCEANIA',
    'SOUTH AMERICA',
    'CENTRAL AMERICA',
    'CARIBBEAN'
  ]

  def self.parse(path, region_dictionary)
    @path = path
    @spreadsheet = Roo::Spreadsheet.open(@path)
    @spreadsheet.parse(clean: true)
    @region_dictionary = region_dictionary

    headers = { i94_code: /^(I-94CountryCode|CountryCode|Code)$/,
                           country: /Country of Residence/,
                           "Jan" => /Jan/,
                           "Feb" => /Feb/,
                           "Mar" => /Mar/,
                           "Apr" => /Apr/,
                           "May" => /May/,
                           "Jun" => /Jun/,
                           "Jul" => /Jul/,
                           "Aug" => /Aug/,
                           "Sep" => /Sep/,
                           "Oct" => /Oct/,
                           "Nov" => /Nov/,
                           "Dec" => /Dec/
                        }

    rows = @spreadsheet.parse(headers)

    rows = filter_rows(rows)

    return transform_rows(rows)
  end

  def self.transform_rows(rows)
    year = @path.split('.')[0].to_i

    new_rows = []
    rows.each do |row|
      country_or_region = row.delete(:country)
      i94_code = row.delete(:i94_code)

      row.each do |k, v|
        date = Date.new(year, Date::ABBR_MONTHNAMES.index(k), 1) 
        date_str = date.strftime("%Y-%m")

        hash = parse_country_or_region(country_or_region, year)
        hash = hash.merge({ date: date_str, i94_code: i94_code.to_i, amount: v.to_i }) unless v.nil?

        new_rows.push(hash) unless v.nil?
      end
    end

    new_rows
  end

  def self.filter_rows(rows)
    rows.reject! { |row| row[:country].nil? } # Remove nils first

    # Remove invalid data:  (everything below MEXICO)
    split_index = rows.index{|row| row[:country].match(/MEXICO/)}
    rows.slice!(split_index..rows.size-1) unless split_index.nil?

    rows.reject! { |row| row[:country].match(/INVALID/) } # Catch any Invalids that slipped through

    rows.delete_at(0) # Remove headers row
    rows
  end

  def self.parse_country_or_region(country_or_region, year)
    if REGIONS.include?(country_or_region)
      region = country_or_region
      country = ""
    else
      country = country_or_region
      region = @region_dictionary.key?(country_or_region) ? @region_dictionary[country_or_region][year.to_s] : ""
    end
    { i94_country: country, i94_region: region }
  end
end