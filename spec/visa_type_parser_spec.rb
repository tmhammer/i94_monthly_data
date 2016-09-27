require 'spec_helper'

describe VisaTypeParser do 
  before(:all) do 
    @expected = JSON.parse( open((File.dirname(__FILE__) + '/expected/2003_visa_types.json')).read, :symbolize_names => true )
  end

  context 'when the file type is .xlsx' do
    it 'parses the document correctly' do
      path = File.dirname(__FILE__) + '/fixtures/2003/Feb.xls'
      result = VisaTypeParser.parse(path)

      expect(result["Western Europe"]).to eq(@expected[:"Western Europe"])
      expect(result["Austria"]).to eq(@expected[:"Austria"])
      expect(result["Belgium"]).to eq(@expected[:"Belgium"])
    end
  end
end