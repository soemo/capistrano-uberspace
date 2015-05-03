namespace :load do
  task :defaults do
    invoke 'uberspace:defaults'
  end
end

namespace :deploy do
  after :published, 'uberspace:restart'
end


