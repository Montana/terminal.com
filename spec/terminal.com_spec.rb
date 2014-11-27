require 'spec_helper'
require 'terminal.com'

describe Terminal::API do
  describe 'constants' do
    it 'specifies API_VERSION' do
      expect(described_class::API_VERSION).to eql('v0.1')
    end

    it 'specifies default headers' do
      expect(described_class::HEADERS['Content-Type']).to eql('application/json')
    end
  end

  describe 'BROWSE SNAPSHOTS & USERS' do
    describe '.get_snapshot(snapshot_id)' do
      it 'fetches info about the snapshot' do
        response = VCR.use_cassette('get_snapshot') do
          described_class.get_snapshot(ubuntu_snap_id)
        end

        expect(response['snapshot']['title']).to eq('Official Ubuntu 14.04')
        expect(response['snapshot']['author']).to eq('terminal')
      end
    end

    describe '.get_profile(profile_id)' do
      it 'fetches info about the profile' do
        response = VCR.use_cassette('get_profile') do
          described_class.get_profile('botanicus')
        end

        expect(response['user']['name']).to eq('James C Russell')
        expect(response['user']['username']).to eq('botanicus')
      end
    end
  end
end
