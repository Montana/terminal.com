describe Terminal do
  describe 'constants' do
    it 'specifies API_VERSION' do
      expect(described_class::API_VERSION).to eql('v0.1')
    end

    it 'specifies default headers' do
      expect(described_class::HEADERS['Content-Type']).to eql('application/json')
    end
  end

  describe '.ensure_options_validity' do
    it 'raises an argument error if provided option is NOT in the list of allowed options' do
      expect {
        described_class.ensure_options_validity({d: 1}, :a, :b, :c)
      }.to raise_error(ArgumentError)
    end

    it 'does NOT raise an error if provided option is in the list of allowed options' do
      expect {
        described_class.ensure_options_validity({a: 1}, :a, :b, :c)
      }.not_to raise_error
    end

    it 'provides a helpful error message' do
      expect {
        described_class.ensure_options_validity({d: 1}, :a, :b, :c)
      }.to raise_error(ArgumentError, /Unrecognised options: :d/)
    end
  end
end
