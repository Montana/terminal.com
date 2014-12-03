describe Terminal do
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

    context 'with either cpu or ram' do
      it 'should raise an argument error if only cpu is provided' do
        expect {
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, cpu: '2 (max)')
        }.to raise_error(ArgumentError)
      end

      it 'should raise an argument error if only ram is provided' do
        expect {
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, ram: 256)
        }.to raise_error(ArgumentError)
      end
    end

    context 'with given cpu and ram' do
      it 'should start given snapshot with cpu 2 (max) and ram 256' do
        response = VCR.use_cassette('start_snapshot_valid_cpu_ram') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, cpu: '2 (max)', ram: 256)
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_valid_cpu_ram.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_valid_cpu_ram') do
          described_class.request_progress(response['request_id'])
        end

        expect(response['result']['cpu']).to eql('2 (max)')
        expect(response['result']['ram']).to eql(256)
      end

      it 'should start given snapshot with cpu 200 and ram 3200' do
        response = VCR.use_cassette('start_snapshot_valid_cpu_ram_2') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, cpu: 200, ram: 3200)
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_valid_cpu_ram_2.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_valid_cpu_ram_2') do
          described_class.request_progress(response['request_id'])
        end

        expect(response['result']['cpu']).to eql(200)
        expect(response['result']['ram']).to eql(3200)
      end
    end

    context 'with given name' do
      it 'should start given snapshot' do
        response = VCR.use_cassette('start_snapshot_with_name') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, name: 'QA: User Listing #356')
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_with_name.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_with_name') do
          described_class.request_progress(response['request_id'])
        end

        expect(response['result']['name']).to eql('QA: User Listing #356')
      end
    end

    context 'with autopause on' do
      it 'should start given snapshot' do
        response = VCR.use_cassette('start_snapshot_with_autopause_on') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, autopause: true)
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_with_autopause_on.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_with_autopause_on') do
          described_class.request_progress(response['request_id'])
        end

        # Autopause isn't propagated to the result object.
        # If this succeeded, we expect everything to be OK.
      end
    end

    context 'with autopause off' do
      it 'should start given snapshot' do
        response = VCR.use_cassette('start_snapshot_with_autopause_off') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, autopause: false)
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_with_autopause_off.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_with_autopause_off') do
          described_class.request_progress(response['request_id'])
        end

        # Autopause isn't propagated to the result object.
        # If this succeeded, we expect everything to be OK.
      end
    end

    context 'with temporary on' do
      it 'should start given snapshot' do
        response = VCR.use_cassette('start_snapshot_with_temporary_on') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, temporary: true)
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_with_temporary_on.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_with_temporary_on') do
          described_class.request_progress(response['request_id'])
        end

        # Temporary isn't propagated to the result object.
        # If this succeeded, we expect everything to be OK.
      end
    end

    context 'with temporary off' do
      it 'should start given snapshot' do
        response = VCR.use_cassette('start_snapshot_with_temporary_off') do
          snapshot_id = '57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234'
          described_class.start_snapshot(user_token, access_token, snapshot_id, temporary: false)
        end

        sleep 16.5 unless File.exist?('spec/low-level/fixtures/start_snapshot_request_progress_with_temporary_off.yml')

        response = VCR.use_cassette('start_snapshot_request_progress_with_temporary_off') do
          described_class.request_progress(response['request_id'])
        end

        # Temporary isn't propagated to the result object.
        # If this succeeded, we expect everything to be OK.
      end
    end

    # :temporary, :startup_script, :custom_data)
    #
    #   "result"=>{"cpu"=>"2 (max)", "ram"=>256, "diskspace"=>10,
    #     "name"=>"Ubuntu 14.04 Base Dev Snapshot",
    #     "snapshot_id"=>"57eff3574ac8d438224dc3aa1c6431a0dbac849a0c254e89be2e758d8113c234",
    #     "status"=>"running", "allow_spot"=>false,
    #     "container_key"=>"d6e9e1ee-d334-4027-b365-5d7eebe5a1d7",
    #     "subdomain"=>"botanicus221", "container_ip"=>"240.3.42.64",
    #     "creation_time"=>1417452412482}}
  end
end
