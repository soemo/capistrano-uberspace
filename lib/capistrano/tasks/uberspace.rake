namespace :uberspace do
  # invoked in capistrano_hooks.rake before :check and :starting
  task :defaults do
    on roles(:web) do |host|
      set :home, "/home/#{host.user}"
    end
  end

  desc "Setup a Uberspace account for serving Rails"
  task setup: [:setup_supervisord, :setup_database_and_config]

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
    supervisord_config = <<-EOF
[program:#{fetch :application}]
command=/home/#{fetch :user}/bin/run-#{fetch :application}-passenger
autostart=yes
autorestart=yes
    EOF

    supervisord_config_stream = StringIO.new(supervisord_config)
    on roles(:web) do
      upload! supervisord_config_stream, "#{fetch :home}/etc/services.d/#{fetch :application}.ini"
    end

    run_config = <<-EOF
#!/bin/bash
cd /var/www/virtual/#{fetch :user}/#{fetch :application}/current
. .env && bin/bundle exec passenger start -p #{fetch :passenger_port} -e production --max-pool-size #{fetch :passenger_max_pool_size} 2>&1
    EOF

    run_config_stream = StringIO.new(run_config)
    on roles(:web) do
      upload! run_config_stream, "#{fetch :home}/bin/run-#{fetch :application}-passenger"
    end
  end
end