require 'spec_helper'
require 'terminal.com'

describe Terminal::API do
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
