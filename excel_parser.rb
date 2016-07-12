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

    headers = { i94_code: /^(I-94CountryCode|Code)$/,
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

    rows.reject! do |row|
      row[:i94_code].nil? | !is_valid_country_term?(row[:country])
    end
    rows.delete_at(0) # Remove headers row

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

  def self.is_valid_country_term?(country)
    excluded_country_terms = [
      'MEXICO Total (Banco de Mexico)',
      'MEXICO (EXCL LAND)',
      'MEXICO Land (Banco de Mexico)',
      'MEXICO'
    ]

    return false if country.nil?
    return false if country.match(/INVALID:/)
    return false if excluded_country_terms.include?(country)
    return true
  end

end