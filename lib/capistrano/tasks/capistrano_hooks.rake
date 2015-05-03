namespace :deploy do
  before :check, 'uberspace:defaults'
  after :published, 'uberspace:restart'
end


