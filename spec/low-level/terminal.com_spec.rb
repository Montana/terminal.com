require 'spec_helper'
require 'terminal.com'

describe Terminal do
  describe 'constants' do
    it 'specifies API_VERSION' do
      expect(described_class::API_VERSION).to eql('v0.1')
    end

    it 'specifies default headers' do
      expect(described_class::HEADERS['Content-Type']).to eql('application/json')
    end
  end
end
