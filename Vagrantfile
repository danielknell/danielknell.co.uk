PLUGINS = %w(vagrant-auto_network vagrant-hostsupdater vagrant-exec
             vagrant-cachier vagrant-triggers)

PLUGINS.reject! { |plugin| Vagrant.has_plugin? plugin }

unless PLUGINS.empty?
  print "The following plugins will be installed: #{PLUGINS.join ", "} continue? [y/n]: "
  if ['yes', 'y'].include? $stdin.gets.strip.downcase
    PLUGINS.each do |plugin|
      system("vagrant plugin install #{plugin}")
      puts
    end
  end
  puts "Please run again"
  exit 1
end

AutoNetwork.default_pool = "172.16.0.0/24"

$host_directory = File.expand_path(File.dirname(__FILE__))
$directory = "/home/vagrant/danielknell"
$virtualenv = "/home/vagrant/env"

$provision = <<SCRIPT
# PACKAGES
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

cat > /etc/apt/sources.list.d/nodesource.list <<EOT
deb https://deb.nodesource.com/node_4.x trusty main
deb-src https://deb.nodesource.com/node_4.x trusty main
EOT

if [ ! -f /root/.last-update ] || [ $(expr $(date +%s) / 60 / 60 / 24) -gt $(expr $(cat /root/.last-update) / 60 / 60 / 24) ]; then
  sudo apt-get -y update
  date +%s | sudo tee /root/.last-update > /dev/null
fi

apt-get -y --force-yes install python3.4-dev python3-pip python-virtualenv nodejs nginx git

# NGINX

rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/site <<EOT
server {
  listen 80;
  root #{$directory}/target;
  index index.html;
  gzip on;
  gzip_types text/plain text/html text/css application/javascript;
  gzip_vary on;
}
EOT

ln -fs /etc/nginx/sites-available/site /etc/nginx/sites-enabled/site

service nginx restart

# APPLICATION

[ ! -d #{$virtualenv} ] && su -c "virtualenv -p $(which python3) #{$virtualenv}" - vagrant

su -c "source #{$virtualenv}/bin/activate && cd #{$directory} && pip install -r requirements.txt" - vagrant

su -c "cd #{$directory} && npm install" - vagrant
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"

  config.vm.network "private_network", :auto_network => true

  config.vm.synced_folder ".", $directory

  config.vm.hostname = "danielknell.vm"

  config.vm.provision "shell", :inline => $provision

  config.ssh.forward_agent = true

  config.hostsupdater.remove_on_suspend = true

  config.cache.scope = :box

  config.cache.synced_folder_opts = {
    type: :nfs,
    mount_options: ["rw", "vers=3", "tcp", "nolock"]
  }

  config.exec.commands "*", directory: $directory

  config.exec.commands "*", env: { "PATH" => "#{$virtualenv}/bin:$PATH" }

  config.exec.commands %w(make)

  def command?(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      }
    end

    return nil
  end

  if command? 'watchman'
    config.trigger.after [:up, :resume], :stdout => true do
      run "watchman watch #{$host_directory}"

      run "watchman -- trigger #{$host_directory} build '**' -X 'target' 'target/**' -- vagrant exec 'cat > /dev/null && make build # '"
    end

    config.trigger.before [:halt, :suspend, :destroy], :stdout => true do
      run "watchman watch-del #{$host_directory}"
    end
  end
end