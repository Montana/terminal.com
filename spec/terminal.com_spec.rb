require 'spec_helper'

describe Terminal::API do
  let(:ubuntu_snap_id) { '987f8d702dc0a6e8158b48ccd3dec24f819a7ccb2756c396ef1fd7f5b34b7980' }

  def vcr(&block)
    VCR.use_cassette('terminal.com', &block)
  end

  describe 'BROWSE SNAPSHOTS & USERS' do
    describe '.get_snapshot(snapshot_id)' do
      it 'fetches info about the snapshot' do
        response = vcr { described_class.get_snapshot(ubuntu_snap_id) }

        expect(response['snapshot']['title']).to eq('Official Ubuntu 14.04')
        expect(response['snapshot']['author']).to eq('terminal')
      end
    end
  end
end
