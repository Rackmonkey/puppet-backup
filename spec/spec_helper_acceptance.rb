require 'beaker-rspec'
require 'pry'
require 'securerandom'

def test_settings
  RSpec.configuration.test_settings
end

RSpec.configure do |c|
  c.add_setting :test_settings, :default => {}
end

proxy_host = ENV['BEAKER_PACKAGE_PROXY'] || ''

if !proxy_host.empty?
  gem_proxy = "http_proxy=#{proxy_host}" unless proxy_host.empty?

  hosts.each do |host|
    on host, "echo 'export http_proxy='#{proxy_host}'' >> /root/.bashrc"
    on host, "echo 'export https_proxy='#{proxy_host}'' >> /root/.bashrc"
    on host, "echo 'export no_proxy=\"localhost,127.0.0.1,localaddress,.localdomain.com,#{host.name}\"' >> /root/.bashrc"
  end
else
  gem_proxy = ''
end

hosts.each do |host|
  # Install Puppet
  if host.is_pe?
    install_pe
  else
    puppetversion = ENV['VM_PUPPET_VERSION']
    on host, "#{gem_proxy} gem install puppet --no-ri --no-rdoc --version '~> #{puppetversion}'"
    on host, "mkdir -p #{host['distmoduledir']}"

    if fact('osfamily') == 'Suse'
      install_package host, 'rubygems ruby-devel augeas-devel libxml2-devel'
      on host, "#{gem_proxy} gem install ruby-augeas --no-ri --no-rdoc"
    end

    on host, 'mkdir -p /var/log/puppetlabs/puppet' if host[:type] == 'aio'
  end

end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'elasticsearch')
    hosts.each do |host|
      copy_hiera_data_to(host, 'spec/fixtures/hiera/hieradata/')
      on(host, 'mkdir -p etc/puppet/modules/another/files/')
    end
  end

  c.after :suite do
    if ENV['ES_VERSION']
      hosts.each do |host|
        timestamp = Time.now
        log_dir = File.join('./spec/logs', timestamp.strftime("%F_%H_%M_%S"))
        FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
      end
    end
  end
end
