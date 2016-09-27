require 'spec_helper'

describe PortsParser do 
  before(:all) do 
    @expected = JSON.parse( open((File.dirname(__FILE__) + '/expected/2002_ports.json')).read, :symbolize_names => true )
  end

  context 'when the file type is .xlsx' do
    it 'parses the document correctly' do
      path = File.dirname(__FILE__) + '/fixtures/2002/Jan.xls'
      result = PortsParser.parse(path)

      expect(result["Japan"]).to eq(@expected[:"Japan"])
    end
  end
end