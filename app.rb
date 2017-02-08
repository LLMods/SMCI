require 'sinatra'
require 'json'

get '/' do
  '<html><body><p>Hello</p></body></html>'
end

post '/payload' do
  push = JSON.parse(request.body.read)
  puts "JSON!!!! #{push.inspect}"
end
