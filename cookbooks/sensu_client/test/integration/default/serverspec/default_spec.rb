require 'spec_helper'

describe 'sensu_client::default' do

  describe service("sensu-client") do
    it { should be_enabled }
    it { should be_running }
  end

end
