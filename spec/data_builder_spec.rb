require 'spec_helper'

describe DataBuilder do 
  before(:all) do 
    class DummyClient
      def initialize 
      end

      def download_file(path)
      end
    end

    @region_dictionary = RegionParser.parse(File.dirname(__FILE__) + '/fixtures/regions.xlsx')
  end

  describe '#build_additional_amounts' do
    let (:file_paths) { [(File.dirname(__FILE__) + '/fixtures/2003/Feb.xls')] }
    let (:expected_visas) { JSON.parse( open((File.dirname(__FILE__) + '/expected/visa_type_lookup.json')).read, symbolize_names: true ) }
    let (:expected_ports) { JSON.parse( open((File.dirname(__FILE__) + '/expected/ports_lookup.json')).read, symbolize_names: true ) }

    it 'builds the correct lookup hashes' do 
      builder = DataBuilder.new(DummyClient.new)
      builder.build_additional_amounts(file_paths) 

      expect( builder.visa_type_dictionary['2003-02']['Western Europe'][:business_visa_arrivals] ).to eq(expected_visas[:'2003-02'][:'Western Europe'][:business_visa_arrivals])
      expect( builder.visa_type_dictionary['2003-02']['Western Europe'][:pleasure_visa_arrivals] ).to eq(expected_visas[:'2003-02'][:'Western Europe'][:pleasure_visa_arrivals])
      expect( builder.visa_type_dictionary['2003-02']['Western Europe'][:student_visa_arrivals] ).to eq(expected_visas[:'2003-02'][:'Western Europe'][:student_visa_arrivals])
      expect( builder.ports_dictionary['2003-02']['Japan'][:ports_arrivals] ).to match_array(expected_ports[:'2003-02'][:'Japan'][:ports_arrivals])
    end
  end

  describe '#build_root_data' do
    let (:file_paths) { ['2015.xlsx', 'canada_mexico.xlsx', 'regions.xlsx'].map!{|p| File.dirname(__FILE__) + "/fixtures/" + p } }
    let (:expected) { JSON.parse( open((File.dirname(__FILE__) + '/expected/root_data.json')).read, symbolize_names: true ) }

    it 'builds the correct data' do 
      builder = DataBuilder.new(DummyClient.new)
      result = builder.build_root_data(file_paths, @region_dictionary) 

      expect(result).to include(*expected)
    end
  end

  describe '#add_additional_amounts' do
    let (:root_file_paths) { ['2015.xlsx', 'canada_mexico.xlsx', 'regions.xlsx'].map!{|p| File.dirname(__FILE__) + "/fixtures/" + p } }
    let (:visa_file_paths) { [(File.dirname(__FILE__) + '/fixtures/2015/Apr.xlsx')] }
    let (:expected) { JSON.parse( open((File.dirname(__FILE__) + '/expected/complete_data.json')).read, symbolize_names: true ) }

    it 'adds the correct fields' do 
      builder = DataBuilder.new(DummyClient.new)

      root_data = builder.build_root_data(root_file_paths, @region_dictionary)
      builder.build_additional_amounts(visa_file_paths)

      results = builder.add_additional_amounts(root_data)
      result = results.select {|entry| entry[:i94_country_or_region] == "Japan" && entry[:date] == "2015-04" }
      expect(result).to eq(expected)
    end
  end
end