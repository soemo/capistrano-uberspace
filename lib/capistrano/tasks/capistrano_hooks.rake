namespace :deploy do
  after :published, 'uberspace:restart'
end
