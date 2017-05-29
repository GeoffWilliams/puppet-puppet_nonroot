require 'spec_helper'
describe 'puppet_nonroot' do
  context 'with default values for all parameters' do
    it { should contain_class('puppet_nonroot') }
  end
end
