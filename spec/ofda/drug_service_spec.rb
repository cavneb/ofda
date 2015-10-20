require 'spec_helper'

describe OFDA::DrugService do
  before(:each) do
    @service = OFDA::DrugService.new(api_key: 'API_KEY')
  end

  describe '#get_uniis_by_name' do
    it 'returns a list of UNIIs' do
      response = {
        "meta": {
          "disclaimer": "openFDA is a beta research project and not for clinical use. While we make every effort to ensure that data is accurate, you should assume all results are unvalidated.",
          "license": "http://open.fda.gov/license",
          "last_updated": "2015-10-13"
        },
        "results": [
          {
            "term": "9ndf7jz4m3",
            "count": 1
          }
        ]
      }
      stub_request(:get, 'https://api.fda.gov/drug/label.json?api_key=API_KEY&count=openfda.unii&search=(openfda.brand_name:XARELTO)').
        to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })

      expect(@service.get_uniis_by_name('xarelto')).to eq([ '9ndf7jz4m3' ])
    end

    it 'returns an empty list if not available' do
      response = { "error": { "code": "NOT_FOUND", "message": "No matches found!" } }
      stub_request(:get, 'https://api.fda.gov/drug/label.json?api_key=API_KEY&count=openfda.unii&search=(openfda.brand_name:FOO)').
          to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })

      expect(@service.get_uniis_by_name('foo')).to eq([])
    end
  end

  describe 'get_brand_names_by_name_and_uniis' do
    it 'returns a key/value pair of unii/brand names' do
      response = { "results": [ { "term": "Xarelto", "count": 1 } ] }
      stub_request(:get, 'https://api.fda.gov/drug/label.json?api_key=API_KEY&count=openfda.brand_name.exact&search=(openfda.unii:9ndf7jz4m3)%20AND%20(openfda.brand_name:XARELTO)').
          to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })
      data = @service.get_brand_names_by_name_and_uniis('xarelto', ['9ndf7jz4m3'])
      expect(data['9ndf7jz4m3']).to eq('Xarelto')
    end
  end

  describe 'get_rxcui_by_unii' do
    it 'returns an RXCUI' do
      response = {"idGroup":{"idType": "UNII_CODE", "id": "9ndf7jz4m3", "rxnormId": ["1114195"]}}
      stub_request(:get, 'http://rxnav.nlm.nih.gov/REST/rxcui.json?idtype=UNII_CODE&id=9ndf7jz4m3').
          to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })
      expect(@service.get_rxcui_by_unii('9ndf7jz4m3')).to eq('1114195')
    end

    it 'returns null with a bad unii code' do
      response = {"idGroup":{"idType":"UNII_CODE","id":"FOO"}}
      stub_request(:get, 'http://rxnav.nlm.nih.gov/REST/rxcui.json?idtype=UNII_CODE&id=FOO').
          to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })
      expect(@service.get_rxcui_by_unii('FOO')).to be_nil
    end
  end

  describe 'get_generic_names_by_rxcui' do
    it 'returns an array of generic names' do
      response = {"propConceptGroup":{"propConcept":[{"propCategory":"NAMES","propName":"RxNorm Name","propValue":"rivaroxaban"}]}}
      stub_request(:get, 'http://rxnav.nlm.nih.gov/REST/rxcui/1114195/allProperties.json?prop=names').
          to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })
      expect(@service.get_generic_names_by_rxcui('1114195')).to eq(['rivaroxaban'])
    end

    it 'returns an empty array when bad rxcui' do
      response = {"propConceptGroup":nil}
      stub_request(:get, 'http://rxnav.nlm.nih.gov/REST/rxcui/12345/allProperties.json?prop=names').
          to_return(:status => 200, :body => response.to_json, :headers => { content_type: 'application/json' })
      expect(@service.get_generic_names_by_rxcui('12345')).to eq([])
    end
  end

end