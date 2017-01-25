require 'spec_helper_acceptance'

# Here we put the more basic fundamental tests, ultra obvious stuff.
describe 'basic tests:' do
  it 'make sure we have copied the module across' do
    shell("find #{default['distmoduledir']}/backup/metadata.json", :acceptable_exit_codes => 0)
  end
end
