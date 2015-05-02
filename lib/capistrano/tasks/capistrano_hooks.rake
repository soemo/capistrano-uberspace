before :setup, 'uberspace:variables'

namespace :deploy do
  before :check, 'uberspace:variables'
  after :published, 'uberspace:restart'
end


