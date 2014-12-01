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


  ############################
  # BROWSE SNAPSHOTS & USERS #
  ############################

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

      it 'fetches all the featured snapshots sorted by date' do
        response = VCR.use_cassette('list_public_snapshots_featured_sorted_by_date') do
          described_class.list_public_snapshots(featured: true, sortby: 'date')
        end

        expect(response['snapshots'].map { |snap| snap['featured'] }).to all(be(true))

        created_at_dates = response['snapshots'].map { |snap| Date.parse(snap['createdAt']) }
        expect(created_at_dates).to eq(created_at_dates.sort.reverse)
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

    describe '.count_public_snapshots(**options)' do
      it 'fetches all the public snapshots by default' do
        response = VCR.use_cassette('count_public_snapshots') do
          described_class.count_public_snapshots
        end

        expect(response['snapshot_count']).to eq(460)
      end

      it 'fetches all the featured snapshots' do
        response = VCR.use_cassette('count_public_snapshots_featured') do
          described_class.count_public_snapshots(featured: true)
        end

        expect(response['snapshot_count']).to eq(136)
      end

      it 'fetches all the snapshots by given username' do
        response = VCR.use_cassette('count_public_snapshots_terminal') do
          described_class.count_public_snapshots(username: 'terminal')
        end

        expect(response['snapshot_count']).to eq(55)
      end

      it 'fetches all the snapshots with given tag' do
        response = VCR.use_cassette('count_public_snapshots_ubuntu') do
          described_class.count_public_snapshots(tag: 'ubuntu')
        end

        expect(response['snapshot_count']).to eq(358)
      end

      it 'fetches all the snapshots with given title' do
        response = VCR.use_cassette('count_public_snapshots_ubuntu_official') do
          described_class.count_public_snapshots(title: 'Official Ubuntu 14.04')
        end

        # Here's a slight caveat, this is not eql, but match. So the following are both valid:
        # ["Official Ubuntu 14.04", "Haskell Platform on Official Ubuntu 14.04"]
        expect(response['snapshot_count']).to eq(17)
      end
    end
  end


  ###############################
  # CREATE AND MANAGE TERMINALS #
  ###############################

  describe 'CREATE AND MANAGE TERMINALS' do
    describe '.list_terminals(user_token, access_token)' do
      it 'lists all my Terminals' do
        response = VCR.use_cassette('list_terminals') do
          described_class.list_terminals(user_token, access_token)
        end

        expect(response['terminals'].length).to eq(2)
        expect(response['terminals'][0]['name']).to eql('Coding Interview: John Doe Jr')
      end
    end

    describe '.get_terminal(user_token, access_token, **options)' do
      context 'with given container_key' do
        it 'retrieves info about given Terminal' do
          response = VCR.use_cassette('get_terminal_with_container_key') do
            container_key = 'b878c064-fc2b-4f14-81fa-ca10ac9385ff'
            described_class.get_terminal(user_token, access_token, container_key: container_key)
          end

          expect(response['terminal']['name']).to eql('Coding Interview: John Doe Jr')
        end
      end

      context 'with given subdomain' do
        it 'retrieves info about given Terminal' do
          response = VCR.use_cassette('get_terminal_with_subdomain') do
            described_class.get_terminal(user_token, access_token, subdomain: 'botanicus117')
          end

          expect(response['terminal']['name']).to eql('Coding Interview: John Doe Jr')
        end
      end
    end

    describe '.start_snapshot(user_token, access_token, snapshot_id, **options)' do
      it 'should start given snapshot' do
        response = VCR.use_cassette('start_snapshot') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id)
        end

        response = VCR.use_cassette('start_snapshot_request_progress') do
          described_class.request_progress(response['request_id'])
        end

        expect(response['status']).to eql('created')
      end

      context 'with given cpu and ram' do
        it 'should start given snapshot' do
          response = VCR.use_cassette('start_snapshot_valid_cpu_ram') do
            snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
            described_class.start_snapshot(user_token, access_token, snapshot_id, cpu: '2 (max)', ram: 256)
          end

          sleep 15.5 unless File.exist?('spec/fixtures/start_snapshot_request_progress_valid_cpu_ram.yml')

          response = VCR.use_cassette('start_snapshot_request_progress_valid_cpu_ram') do
            described_class.request_progress(response['request_id'])
          end

          expect(response['status']).to eql('success')
          expect(response['result']['cpu']).to eql('2 (max)')
          expect(response['result']['ram']).to eql(256)
        end

        it 'should start given snapshot' do
          response = VCR.use_cassette('start_snapshot_valid_cpu_ram_2') do
            snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
            described_class.start_snapshot(user_token, access_token, snapshot_id, cpu: 200, ram: 800)
          end

          request_id = response['request_id']

          sleep 16 unless File.exist?('spec/fixtures/start_snapshot_request_progress_valid_cpu_ram_2.yml')

          response = VCR.use_cassette('start_snapshot_request_progress_valid_cpu_ram_2') do
            described_class.request_progress(request_id)
          end

          p response

          # :cpu, :ram, :temporary, :name, :autopause, :startup_script, :custom_data)
          #   "result"=>{"cpu"=>"2 (max)", "ram"=>256, "diskspace"=>10,
          #     "name"=>"Ubuntu 14.04 Base Dev Snapshot",
          #     "snapshot_id"=>"57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234",
          #     "status"=>"running", "allow_spot"=>false,
          #     "container_key"=>"d6e9e1ee-d334-4027-b365-5d7eebe5a1d7",
          #     "subdomain"=>"botanicus221", "container_ip"=>"240.3.42.64",
          #     "creation_time"=>1417452412482}}
          # expect(response['result']).to
          expect(response['status']).to eql('created')
          expect(response['result']['cpu']).to eql(200)
          expect(response['result']['ram']).to eql(800)
        end
      end
    end
  end
end
