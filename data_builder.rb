require './dropbox_client'
require './excel_parser'
require './canada_mexico_parser'
require './visa_type_parser'
require './ports_parser'

class DataBuilder

  attr_accessor :visa_type_dictionary, :ports_dictionary

  def initialize(client = nil)
    @client = client ? client : DropboxClientWrapper.new
    @visa_type_dictionary = {}
    @ports_dictionary = {}
  end

  def run
    file_paths = get_all_file_paths

    download_all_files(file_paths[:root] + file_paths[:visa_type])

    new_paths = { visa_type: file_paths[:visa_type].map{|p| p.gsub!('/', '')} }
    new_paths[:root] = file_paths[:root].map{|p| p.gsub!('/', '')}

    region_dictionary = RegionParser.parse('regions.xlsx')
    additional_amounts_dictionary = build_additional_amounts(new_paths[:visa_type])
    root_data = build_root_data(new_paths[:root], region_dictionary)
    data = add_additional_amounts(root_data)

    delete_all_files(new_paths[:visa_type] + new_paths[:root])

    write_json_file(data)
    #write_csv_file(data)

    # # Write out to the sqlite database using scraperwiki library
    #ScraperWiki.save_sqlite([:date, :i94_code, :i94_country, :i94_region], data)
  end

  def add_additional_amounts(root_data)
    root_data.each do |entry|
      if @visa_type_dictionary.key?(entry[:date]) && @visa_type_dictionary[entry[:date]].key?(entry[:i94_country_or_region])
        entry.merge!(@visa_type_dictionary[entry[:date]][entry[:i94_country_or_region]])
      else
        entry.merge!({business_visa_arrivals: "", pleasure_visa_arrivals: "", student_visa_arrivals: ""})
      end

      if @ports_dictionary.key?(entry[:date]) && @ports_dictionary[entry[:date]].key?(entry[:i94_country_or_region])
        entry.merge!(@ports_dictionary[entry[:date]][entry[:i94_country_or_region]])
      else
        entry.merge!(ports_arrivals: [])
      end
    end

    root_data
  end

  def build_root_data(file_paths, region_dictionary)
    data = []
    file_paths.each do |path|
      next if path.include?("regions.xlsx")
      if path.include?("canada_mexico.xlsx")
        new_data = CanadaMexicoParser.parse(path)
      else
        new_data = ExcelParser.parse(path, region_dictionary)
      end
      data.concat new_data
    end
    data
  end

  def build_additional_amounts(file_paths)
    file_paths.each do |path|
      year = path.match(/[0-9]{4}/)[0]
      month = path.match(/[A-Z][a-z]{2}.xls/)[0].sub!('.xls', '')

      date = Date.new(year.to_i, Date::ABBR_MONTHNAMES.index(month), 1) 
      date_str = date.strftime("%Y-%m")

      @visa_type_dictionary[date_str] = VisaTypeParser.parse(path)
      @ports_dictionary[date_str] = PortsParser.parse(path)
    end
  end

  def get_visa_type_file_paths
    year_paths = @client.get_file_paths('/visa_type')
    file_paths = []
    year_paths.each do |pos|
      file_paths.concat @client.get_file_paths(pos)
    end
    file_paths
  end

  def get_all_file_paths
    file_paths = { root: @client.get_file_paths('/') }
    file_paths[:root].delete('/visa_type')
    file_paths[:visa_type] = get_visa_type_file_paths
    file_paths
  end

  def download_all_files(file_paths)
    file_paths.each { |path| @client.download_file(path) }
  end

  def delete_all_files(file_paths)
    file_paths.each { |path| File.delete(path) }
  end

  def write_json_file(data)
    File.open('i94.json', 'w'){|f| f.write(JSON.pretty_generate(data))}
  end

  #def self.write_csv_file(translated_rows)
  #  CSV.open("i94.csv", "wb") do |csv|
  #    csv << ["i94_country_or_region", "ntto_groups", "date", "i94_code", "total_amount", "business_visa_amount", "pleasure_visa_amount", "student_visa_amount"]
  #    translated_rows.each do |row|
  #      csv << [row[:i94_country_or_region], row[:ntto_groups].join(';'), row[:date], row[:i94_code], row[:total_amount], row[:business_visa_amount], row[:pleasure_visa_amount], row[:student_visa_amount]]
  #    end
  #  end
  #end
end