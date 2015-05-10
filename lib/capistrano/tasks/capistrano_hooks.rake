before :setup, 'uberspace:defaults'

namespace :deploy do
  before :check, 'uberspace:defaults'
  before :starting, 'uberspace:defaults'
  after :published, 'uberspace:restart'
end


