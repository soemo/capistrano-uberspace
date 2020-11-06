namespace :uberspace do
  # invoked in capistrano_hooks.rake before :check and :starting
  task :defaults do
    on roles(:web) do |host|
      set :home, "/home/#{host.user}"
    end
  end

  desc "Setup a Uberspace account for serving Rails"
  task setup: [:setup_supervisord, :setup_reverse_proxy, :setup_database_and_config]

  desc "Start the Rails Server"
  task :start do
    on roles(:web) do
      execute "supervisorctl start #{fetch :application}"
    end
  end

  desc "Stop the Rails Server"
  task :stop do
    on roles(:web) do
      execute "supervisorctl stop #{fetch :application}"
    end
  end

  desc "Restart the Rails server"
  task :restart do
    on roles(:web) do
      execute "supervisorctl restart #{fetch :application}"
    end
  end

  desc "Setup uberspace's MySQL server"
  task setup_database_and_config: :defaults do
    on roles(:web) do |host|
      my_cnf = capture('cat ~/.my.cnf')
      config = {}
      db_suffix = fetch(:database_name_suffix) ? "#{fetch :database_name_suffix}" : "#{fetch :application}"
      database_name = "#{host.user}_#{db_suffix}_#{fetch :stage}"
      env = (fetch :stage).to_s

      config[env] = {
          'adapter' => 'mysql2',
          'encoding' => 'utf8',
          'database' => database_name,
          'host' => 'localhost'
      }

      config[env]['username'] = my_cnf.scan(/^user=(.*)\r?$/)[0][0]

      config[env]['password'] = my_cnf.scan(/^password=(.*)\r?$/)[0][0]

      config[env]['port'] = 3306

      execute "mysql -e 'CREATE DATABASE IF NOT EXISTS #{database_name} CHARACTER SET utf8 COLLATE utf8_general_ci;'"

      execute "mkdir -p #{fetch :deploy_to}/shared/config"
      database_yml = StringIO.new(config.to_yaml)
      upload! database_yml, "#{fetch :deploy_to}/shared/config/database.yml"
      upload! 'config/master.key', "#{fetch :deploy_to}/shared/config/master.key"
    end
  end

  desc "Setup supervisord"
  task setup_supervisord: :defaults do
    app_config = <<-EOF
[program:#{fetch :application}]
command=. .env && exec bundle exec passenger start -p #{fetch :passenger_port} -e production --max-pool-size #{fetch :passenger_max_pool_size} 2>&1
directory=#{fetch :deploy_to}/current
autostart=yes
autorestart=yes
    EOF

    app_config_stream = StringIO.new(app_config)
    on roles(:web) do
      upload! app_config_stream, "#{fetch :home}/etc/services.d/#{fetch :application}.ini"
    end
  end

  task setup_reverse_proxy: :defaults do
    on roles(:web) do |host|
      htaccess = <<-EOF
DirectoryIndex disabled
RewriteEngine On
RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ http://#{host.user}.local.uberspace.de:#{fetch :passenger_port}/$1 [P]
      EOF
      htaccess_stream = StringIO.new(htaccess)
      path = "/var/www/virtual/#{host.user}/html"
      execute "mkdir -p #{path}"
      upload! htaccess_stream, "#{path}/.htaccess"
      execute "chmod +r #{path}/.htaccess"
    end
  end
end