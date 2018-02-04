def get_ruby_version
  ruby_version_file = ".ruby-version"
  if File.exists?(ruby_version_file)
    File.read(ruby_version_file).strip
  else
    abort("Please provide a '.ruby-version' file with a ruby version supported by Uberspace.")
  end
end

task :setup do
  # Set a random, ephemeral port, and hope it's free.
  # Could be refactored to actually check whether it is.

  invoke "uberspace:ruby"
  invoke "uberspace:gemrc"
  invoke "uberspace:setup_svscan"
  invoke "uberspace:setup_daemon"
  invoke "uberspace:setup_reverse_proxy"
  invoke "uberspace:setup_database_and_config"
end

namespace :uberspace do
  # invoked in capistrano_hooks.rake before :check and :starting
  task :defaults do
    on roles(:web) do |host|
      set :home, "/home/#{host.user}"
    end
  end

  desc "Setup uberspace's MySQL server"
  task :setup_database_and_config do
    on roles(:web) do |host|
      my_cnf = capture('cat ~/.my.cnf')
      config = {}
      db_suffix = fetch(:database_name_suffix) ? "#{fetch :database_name_suffix}" : "#{fetch :application}"
      %w(development production test).each do |env|

        config[env] = {
            'adapter' => 'mysql2',
            'encoding' => 'utf8',
            'database' => "#{host.user}_rails_#{db_suffix}_#{env}",
            'host' => 'localhost'
        }

        my_cnf.scan(/^user=(\w+)/)
        config[env]['username'] = $1

        my_cnf.scan(/^password=(\w+)/)
        config[env]['password'] = $1

        my_cnf.scan(/^port=(\d+)/)
        config[env]['port'] = $1.to_i

        execute "mysql -e 'CREATE DATABASE IF NOT EXISTS #{config[env]['database']} CHARACTER SET utf8 COLLATE utf8_general_ci;'"
      end

      execute "mkdir -p #{fetch :deploy_to}/shared/config"
      database_yml = StringIO.new(config.to_yaml)
      upload! database_yml, "#{fetch :deploy_to}/shared/config/database.yml"
    end
  end

  task :start do
    on roles(:web) do
      execute "svc -u #{fetch :home}/service/rails-#{fetch :application}"
    end
  end

  task :stop do
    on roles(:web) do
      execute "svc -d #{fetch :home}/service/rails-#{fetch :application}"
    end
  end

  task :restart do
    on roles(:web) do
      execute "svc -du #{fetch :home}/service/rails-#{fetch :application}"
    end
  end


  desc "Setup svscan - for your personal service directory"
  task :setup_svscan do
    on roles(:web) do
      execute 'test -d ~/service || uberspace-setup-svscan ; echo 0'
    end
  end


  desc "Setup daemontools"
  task :setup_daemon do

    daemon_script = <<-EOF
#!/bin/bash
export HOME=#{fetch :home}
source $HOME/.bash_profile
cd #{fetch :deploy_to}/current
. .env && exec bundle exec passenger start -p #{fetch :passenger_port} -e production --max-pool-size #{fetch :passenger_max_pool_size} 2>&1
      EOF

    log_script = <<-EOF
#!/bin/sh
exec multilog t ./main
    EOF

    daemon_script_stream = StringIO.new(daemon_script)
    log_script_stream = StringIO.new(log_script)
    on roles(:web) do
      execute                        "mkdir -p #{fetch :home}/etc/run-rails-#{fetch :application}"
      execute                        "mkdir -p #{fetch :home}/etc/run-rails-#{fetch :application}/log"
      upload! daemon_script_stream,  "#{fetch :home}/etc/run-rails-#{fetch :application}/run"
      upload! log_script_stream,     "#{fetch :home}/etc/run-rails-#{fetch :application}/log/run"
      execute                        "chmod +x #{fetch :home}/etc/run-rails-#{fetch :application}/run"
      execute                        "chmod +x #{fetch :home}/etc/run-rails-#{fetch :application}/log/run"
      execute                        "ln -nfs #{fetch :home}/etc/run-rails-#{fetch :application} #{fetch :home}/service/rails-#{fetch :application}"
    end
  end

  task :setup_reverse_proxy do
      htaccess = <<-EOF
RewriteEngine On
RewriteBase /

# ensure the browser supports gzip encoding
RewriteCond %{HTTP:Accept-Encoding} \b(x-)?gzip\b
RewriteCond %{REQUEST_FILENAME}.gz -s
RewriteRule ^(.+) $1.gz [L]

# ensure correct Content-Type and add encoding header
<FilesMatch \.css\.gz$>
  ForceType text/css
  Header set Content-Encoding gzip
</FilesMatch>

<FilesMatch \.js\.gz$>
  ForceType text/javascript
  Header set Content-Encoding gzip
</FilesMatch>

# cache assets like forever
<FilesMatch \.(js|css|gz|jpe?g|gif|png|ico)$>
  Header unset ETag
  FileETag None
  ExpiresActive On
  ExpiresDefault "access plus 1 year"
</FilesMatch>

# let rails handle everything else
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ http://localhost:#{fetch :passenger_port}/$1 [P]
      EOF
      htaccess_stream = StringIO.new(htaccess)
      path = fetch(:domain) ? "/var/www/virtual/#{fetch :user}/#{fetch :domain}" : "#{fetch :home}/html"
      on roles(:web) do
        execute                  "mkdir -p #{path}"
        upload! htaccess_stream, "#{path}/.htaccess"
        execute                  "chmod +r #{path}/.htaccess"
        execute                  "uberspace-add-domain -qwd #{fetch :domain} ; true" if fetch(:domain)
    end
  end

  task :ruby do
    ruby_version = fetch(:ruby_version, -> { get_ruby_version })
    path_settings = <<-END
export PATH=/package/host/localhost/ruby-#{ruby_version}/bin:$PATH
export PATH=$HOME/.gem/ruby/#{ruby_version}/bin:$PATH
END
    on roles(:web) do
      # Remove old rubies
      execute "sed -i '/\\\/ruby-/d' .bashrc"
      execute "echo '#{path_settings}' >> .bashrc"
    end
  end

  task :gemrc do
    on roles(:web) do
      execute 'echo "gem: --user-install --no-rdoc --no-ri" > ~/.gemrc'
    end
  end
end

