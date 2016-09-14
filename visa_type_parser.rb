require 'roo' 
require 'roo-xls'          
require 'open-uri'
require './decapitalize'

class VisaTypeParser
  extend Decapitalize

  def self.parse(path)
    @path = path
    @spreadsheet = Roo::Spreadsheet.open(@path)
    @spreadsheet.parse(clean: true)

    headers = { country_or_region: "OF RESIDENCE",
                           business: "BUSINESS",
                           pleasure: "PLEASURE",
                           student: "STUDENT",
                        }

    rows = @spreadsheet.sheet(3).parse(headers)

    filter_rows(rows)

    return build_hash(rows)
  end

  def self.filter_rows(rows)
    rows.reject! { |row| row[:country_or_region].nil? } # Remove nils first
  end

  def self.build_hash(rows)
    year = @path.match(/[0-9]{4}/)[0]
    month = @path.match(/[A-Z][a-z]{2}/)[0]

    date = Date.new(year.to_i, Date::ABBR_MONTHNAMES.index(month), 1) 
    date_str = date.strftime("%Y-%m")

    hash = {}
    rows.each do |row|
      hash[decapitalize(row[:country_or_region])] = {
        date_str => {
          business_visa_amount: row[:business].to_i,
          pleasure_visa_amount: row[:pleasure].to_i,
          student_visa_amount: row[:student].to_i
      }}
    end

    hash
  end
end