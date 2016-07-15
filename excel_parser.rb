require 'roo' 
require 'roo-xls'          
require 'open-uri'
require 'csv'
require 'yaml'

class ExcelParser

  def self.parse(path)
    @path = path
    @spreadsheet = Roo::Spreadsheet.open(@path)
    @spreadsheet.parse(clean: true)

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
      country = row.delete(:country)
      i94_code = row.delete(:i94_code)

      row.each do |k, v|
        date = Date.new(year, Date::ABBR_MONTHNAMES.index(k), 1) 
        date_str = date.strftime("%Y-%m")
        new_rows.push({ date: date_str, i94_code: i94_code, country: country, amount: v })
      end
    end

    new_rows
  end

  def self.filter_rows(rows)
    rows.reject! { |row| row[:country].nil? } # Remove nils first

    # Remove invalid data:  (everything below MEXICO)
    split_index = rows.index{|row| row[:country].match(/MEXICO/)}
    rows.slice!(split_index..rows.size-1)

    rows.reject! { |row| row[:country].match(/INVALID/) } # Catch any Invalids that slipped through

    rows.delete_at(0) # Remove headers row
    rows
  end
end