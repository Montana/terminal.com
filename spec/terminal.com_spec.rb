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

    describe '.list_public_snapshots(**options)' do
      it 'fetches all the public snapshots by default' do
        response = VCR.use_cassette('list_public_snapshots') do
          described_class.list_public_snapshots
        end

        expect(response['snapshots'].length).to eq(460)
      end

      it 'fetches all the featured snapshots' do
        response = VCR.use_cassette('list_public_snapshots_featured') do
          described_class.list_public_snapshots(featured: true)
        end

        expect(response['snapshots'].map { |snap| snap['featured'] }).to all(be(true))
      end

      it 'fetches all the snapshots by given username' do
        response = VCR.use_cassette('list_public_snapshots_terminal') do
          described_class.list_public_snapshots(username: 'terminal')
        end

        expect(response['snapshots'].map { |snap| snap['author'] }).to all(eq('terminal'))
      end

      it 'fetches all the snapshots with given tag' do
        response = VCR.use_cassette('list_public_snapshots_ubuntu') do
          described_class.list_public_snapshots(tag: 'ubuntu')
        end

        expect(response['snapshots'].map { |snap| snap['tags'] }).to all(include('ubuntu'))
      end

      it 'fetches all the snapshots with given title' do
        response = VCR.use_cassette('list_public_snapshots_ubuntu_official') do
          described_class.list_public_snapshots(title: 'Official Ubuntu 14.04')
        end

        # Here's a slight caveat, this is not eql, but match. So the following are both valid:
        # ["Official Ubuntu 14.04", "Haskell Platform on Official Ubuntu 14.04"]
        expect(response['snapshots'].map { |snap| snap['title'] }).to all(match('Official Ubuntu 14.04'))
      end

      it 'fetches all the featured snapshots sorted by popularity' do
        response = VCR.use_cassette('list_public_snapshots_featured_sorted_by_popularity') do
          described_class.list_public_snapshots(featured: true, sortby: 'popularity')
        end

        expect(response['snapshots'].map { |snap| snap['featured'] }).to all(be(true))

        start_counts = response['snapshots'].map { |snap| snap['start_count'] }
        expect(start_counts).to eq(start_counts.sort.reverse)
      end

      context 'with pagination' do
        it 'fetches first page of the public snapshots' do
          response = VCR.use_cassette('list_public_snapshots_page_1') do
            described_class.list_public_snapshots(page: 1, perPage: 1)
          end

          expect(response['snapshots'].length).to eq(1)
        end

        it 'fetches subsequent pages of the public snapshots' do
          page_one = VCR.use_cassette('list_public_snapshots_page_1') do
            described_class.list_public_snapshots(page: 1, perPage: 1)
          end

          page_two = VCR.use_cassette('list_public_snapshots_page_2') do
            described_class.list_public_snapshots(page: 2, perPage: 1)
          end

          expect(page_one['snapshots'].length).to eq(1)
          expect(page_two['snapshots'].length).to eq(1)

          expect(page_one).not_to eql(page_two)
        end
      end
    end
  end
end
