require 'spec_helper'

require 'mcollective/monkey_patches'

describe OpenSSL::SSL::SSLContext do
  it 'disables SSLv2 via the SSLContext#options bitmask' do
    (subject.options & OpenSSL::SSL::OP_NO_SSLv2).should == OpenSSL::SSL::OP_NO_SSLv2
  end
  it 'explicitly disable SSLv2 ciphers using the ! prefix so they cannot be re-added' do
    cipher_str = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers]
    cipher_str.split(':').should include('!SSLv2')
  end
  it 'sets parameters on initialization' do
    described_class.any_instance.expects(:set_params)
    subject
  end
  it 'has no ciphers with version SSLv2 enabled' do
    ciphers = subject.ciphers.select do |name, version, bits, alg_bits|
      /SSLv2/.match(version)
    end
    ciphers.should be_empty
  end
end
