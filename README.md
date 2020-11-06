# Capistrano::Uberspace recipes for Capistrano 3

Capistrano::Uberspace helps you deploy a Ruby on Rails app on Uberspace, a popular shared hosting provider. It's based on (Uberspacify)[https://github.com/yeah/uberspacify]

All the magic is built into a couple nice Capistrano scripts.

The scripts will:

- Add a database that corresponds to your app's name
- Generate a `database.yml` configuration for use on your server
- Generate a `.htaccess` file
- configure `supervisord` so that it monitors your rails server

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'capistrano-uberspace', github: 'soemo/capistrano-uberspace', branch: 'master', group: :development
```

And then execute:

    $ bundle

This should install Capistrano::Uberspace as well as Capistrano and some other gems for you.

Now execute the following to get a `Capfile` and a `deploy.rb`:

    $ cap install

Now, you need to add a few lines to some configuration files. If you haven't used Capistrano previously, it is safe to overwrite the `Capfile` and copy, paste & adapt the following:

```ruby
# Capfile

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# include rails tasks
require 'capistrano/rails'

# include uberspace tasks
require 'capistrano/uberspace'

# ...

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }

```

`config/deploy/{stage}.rb`
```ruby
# the Uberspace server you are on
server 'phoenix.uberspace.de', user: 'ubernaut', roles: %w{app db web}
set :deploy_to, "/home/ubernaut/#{fetch :application}"
```

In `config/deploy.rb` you need to these parameters:

 - `application`
 - `repository`
 -

```
# a name for your app, [a-z0-9] should be safe, will be used for your gemset,
# databases, directories, etc.
set :application, 'dummyapp'

# the repo where your code is hosted (possibly in your uberspace home as well)
set :repository, 'https://github.com/yeah/dummyapp.git'

# Your database configuration as well as your secrets will stay across deploys.
append :linked_files, "config/database.yml", "config/master.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", 'bundle'

# By default, Capistrano::Uberspace uses the ruby versions installed on your uberspace that matches your `.ruby-version` file.
```

Done. That was the hard part. It's easy from here on out. Next, add all new/modified files to version control. If you use Git, the following will do:

    $ git add . ; git commit -m 'uberspacify my app!' ; git push

And here comes the fun part - get it all up and running on Uberspace! These commands should teleport your app to the Uberspace (execute them one by one and keep an eye on the output):

    $ bundle exec cap {stage} uberspace:setup
    $ bundle exec cap {stage} deploy

(Be sure to have your public key set up on your Uberspace account already.)

This will do a whole lot of things, so don't get nervous.

Now, **after some time**, your app should be available on your Uberspace URI.

Should you ever need to stop/start/restart your app, you can do so using Capistrano's standard:

    $ bundle exec cap deploy:{stop|start|restart}

That's it folks. Have fun.

## License

MIT; Copyright (c) 2012 Jan Schulz-Hofen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request