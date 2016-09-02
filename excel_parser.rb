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
    @ntto_groups = build_ntto_groups

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

  def self.build_ntto_groups
    ntto_groups = {}
    ntto_groups[:visa_waiver] = YAML.load_file('visa_waiver_countries.yaml')
    ntto_groups[:apec] = YAML.load_file('apec_countries.yaml')
    ntto_groups[:eu] = YAML.load_file('eu_countries.yaml')
    ntto_groups[:oecd] = YAML.load_file('oecd_countries.yaml')
    ntto_groups[:pata] = YAML.load_file('pata_countries.yaml')

    ntto_groups
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
        add_ntto_groups(hash)

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
    country_or_region = decapitalize(country_or_region)

    if REGIONS.include?(country_or_region)
      regions = [country_or_region]
    else
      regions = @region_dictionary.key?(country_or_region) ? [@region_dictionary[country_or_region][year.to_s]] : []
    end
    { i94_country_or_region: country_or_region, ntto_groups: regions }
  end

  def self.decapitalize(country_or_region)
    country_or_region_dup = country_or_region.dup
    country_or_region.scan(/([A-Z]+)/).each do |word|
      word = word.first

      next if ( word == 'USSR' || word == 'PRC' )

      new_word = word.downcase
      new_word = new_word.capitalize unless ( new_word == "of" || new_word == "and" )

      country_or_region_dup.sub!(word, new_word)
    end

    return country_or_region_dup
  end

  def self.add_ntto_groups(hash)
    if @ntto_groups[:visa_waiver].include?(hash[:i94_country_or_region])
      hash[:ntto_groups].push 'Visa Waiver'
    elsif !REGIONS.include?(hash[:i94_country_or_region])
      hash[:ntto_groups].push 'Non-Visa Waiver'
    end

    hash[:ntto_groups].push('APEC (Asia Pacific Economic Cooperation)') if @ntto_groups[:apec].include?(hash[:i94_country_or_region])
    hash[:ntto_groups].push('EU (European Union)') if @ntto_groups[:eu].include?(hash[:i94_country_or_region])
    hash[:ntto_groups].push 'OECD (Organization for Economic Cooperation and Development)' if @ntto_groups[:oecd].include?(hash[:i94_country_or_region])
    hash[:ntto_groups].push 'PATA (Pacific Asia Travel Association)' if @ntto_groups[:pata].include?(hash[:i94_country_or_region])

    hash[:ntto_groups].push 'Overseas'
  end
end