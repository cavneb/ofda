require 'typhoeus'
require 'addressable/uri'
require 'json'

module OFDA
  class DrugService
    include FdaSearchTermUtils

    FDA_DRUG_LABEL_URL = 'https://api.fda.gov/drug/label.json'
    DAILY_MED_AUTOCOMPLETE_URL = 'https://dailymed.nlm.nih.gov/dailymed/autocomplete.cfm'
    RXNAV_URL = 'http://rxnav.nlm.nih.gov/REST/rxcui'

    attr_accessor :api_key

    def initialize(api_key:)
      @api_key = api_key
    end

    # 1. Gets the UNIIs by name
    # 2. Gets the brand names by UNII and name
    # 3. Gets the RXCUI by UNII
    # 4. Gets the generic name by RXCUI
    # 5. Returns response
    #
    # Example Response:
    #   [
    #     {
    #       "unii": "9NDF7JZ4M3",
    #       "brand_name": "XARELTO",
    #       "generic_name": "RIVAROXABAN",
    #       "rxcui": 1114195,
    #       "active_ingredients": [
    #         "RIVAROXABAN"
    #       ]
    #     }
    #   ]

    def search(name)
      uniis = get_uniis_by_name(name)
      return [] unless uniis.length > 0

      ret = []

      brand_names = get_brand_names_by_name_and_uniis(name, uniis)
      brand_names.each do |unii, brand_name|
        drug = {}
        rxcui = get_rxcui_by_unii(unii)
        generic_names = get_generic_names_by_rxcui(rxcui)
        drug[:unii] = unii
        drug[:brand_name] = brand_name.upcase
        drug[:rxcui] = rxcui
        drug[:generic_name] = generic_names.first.upcase
        drug[:active_ingredients] = generic_names.map(&:upcase)
        ret << drug
      end

      ret
    end

    def get_uniis_by_name(name)
      uri = Addressable::URI.new
      uri.query_values = {
          api_key: api_key,
          search: "(openfda.brand_name:#{make_fda_safe(name)})",
          count: 'openfda.unii'
      }
      url = "#{FDA_DRUG_LABEL_URL}?#{URI.unescape(uri.query)}"

      response = Typhoeus.get(url)
      data = JSON.parse(response.body)
      if data['results']
        data['results'].map { |t| t['term'] }
      else
        []
      end
    end

    def get_brand_names_by_name_and_uniis(name, uniis)
      requests = {}
      hydra = Typhoeus::Hydra.hydra

      uniis.each do |unii|
        requests[unii] = build_brand_names_by_name_and_unii_request(name, unii)
      end

      requests.each do |unii, req|
        hydra.queue(req)
      end

      hydra.run

      responses = {}
      requests.map { |unii, request| responses[unii] = JSON.parse(request.response.body) }

      ret = {}
      responses.each do |unii, data|
        ret[unii] = if data['results']
                      data['results'].map { |t| t['term'] }.first
                    else
                      ''
                    end
      end
      ret
    end

    def get_rxcui_by_unii(unii)
      uri = Addressable::URI.new
      uri.query_values = {
          idtype: 'UNII_CODE',
          id: unii
      }
      url = "#{RXNAV_URL}.json?#{URI.unescape(uri.query)}"

      response = Typhoeus.get(url)

      data = JSON.parse(response.body)
      if data['idGroup']['rxnormId']
        data['idGroup']['rxnormId'][0]
      else
        nil
      end
    end

    def get_generic_names_by_rxcui(rxcui)
      url = "#{RXNAV_URL}/#{rxcui}/allProperties.json?prop=names"
      response = Typhoeus.get(url)
      data = JSON.parse(response.body)
      if data['propConceptGroup']
        data['propConceptGroup']['propConcept'].map { |t| t['propValue'] }
      else
        []
      end
    end

    private

    def build_brand_names_by_name_and_unii_request(name, unii)
      uri = Addressable::URI.new
      uri.query_values = {
          api_key: api_key,
          search: "(openfda.unii:#{unii})+AND+(openfda.brand_name:#{make_fda_safe(name)})",
          count: 'openfda.brand_name.exact'
      }
      url = "#{FDA_DRUG_LABEL_URL}?#{URI.unescape(uri.query)}"

      Typhoeus::Request.new(url)
    end
  end
end
