require 'spec_helper'

describe OFDA::FdaSearchTermUtils do
  before(:each) do
    @object = Object.new
    @object.extend(OFDA::FdaSearchTermUtils)
  end

  describe '#is_fda_safe' do
    it 'returns true if valid number, character or dash' do
      expect(@object.is_fda_safe?('a')).to be_truthy
      expect(@object.is_fda_safe?('3')).to be_truthy
      expect(@object.is_fda_safe?('-')).to be_truthy
    end

    it 'returns false if invalid character' do
      expect(@object.is_fda_safe?(nil)).to be_falsey
      expect(@object.is_fda_safe?('""')).to be_falsey
      expect(@object.is_fda_safe?(' ')).to be_falsey
    end
  end

  describe '#make_fda_safe' do
    it 'returns an emptry string when null value passed' do
      expect(@object.make_fda_safe(nil)).to eq('')
    end

    it 'returns a capitalized string' do
      expect(@object.make_fda_safe('xarelto')).to eq('XARELTO')
    end

    it 'removes "AND" from the words' do
      expect(@object.make_fda_safe('foo and bar')).to eq('FOO BAR')
    end

    it 'replaces invalid characters with spaces' do
      expect(@object.make_fda_safe('s&fl!fG-!')).to eq('S FL FG-')
    end
  end
end
