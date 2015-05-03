namespace :deploy do
  before :starting, 'uberspace:defaults'
  after :published, 'uberspace:restart'
end


