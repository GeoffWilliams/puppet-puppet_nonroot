require 'spec_helper'
describe 'puppet_nonroot', :type => :define do
  let :title do
    "nra.puppet"
  end

  let :params do
    {
      :user               => "bob",
      :puppet_master_fqdn => "puppet.fake",
      :challenge_password => "top_secret",
    }
  end

  context 'with default values for all parameters' do
    it { should compile }
  end
end
