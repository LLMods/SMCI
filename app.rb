require 'sinatra'
require 'json'

get '/' do
  '<html><body><p>Hello</p></body></html>'
end

post '/payload' do
  push = JSON.parse(request.body.read)
  File.open('some_file.txt', 'w') do |f|
    f.write("JSON!!! #{push.inspect}")
  end
end
