require 'spec_helper'

describe ExcelParser do 
  before(:all) do 
    @region_dictionary = RegionParser.parse(File.dirname(__FILE__) + '/fixtures/regions.xlsx')
    @expected = JSON.parse( open((File.dirname(__FILE__) + '/expected/2015_main.json')).read, :symbolize_names => true )
  end

  context 'when the file type is .xlsx' do
    it 'parses the document correctly' do
      path = File.dirname(__FILE__) + '/fixtures/2015.xlsx'
      result = ExcelParser.parse(path, @region_dictionary)
      expect(result[0..12]).to match_array(@expected)
    end
  end
end