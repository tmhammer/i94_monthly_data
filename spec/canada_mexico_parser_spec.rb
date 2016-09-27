require 'spec_helper'

describe CanadaMexicoParser do 
  before(:all) do 
    @expected = JSON.parse( open((File.dirname(__FILE__) + '/expected/canada_mexico.json')).read, :symbolize_names => true )
  end

  context 'when the file type is .xlsx' do
    it 'parses the document correctly' do
      path = File.dirname(__FILE__) + '/fixtures/canada_mexico.xlsx'
      result = CanadaMexicoParser.parse(path)

      expect(result.size).to eq(828)
      expect(result).to include(*@expected)
    end
  end
end