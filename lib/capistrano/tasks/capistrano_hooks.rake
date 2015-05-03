before :setup, 'uberspace:defaults'

namespace :deploy do
  before :starting, 'uberspace:defaults'
  after :published, 'uberspace:restart'
end


