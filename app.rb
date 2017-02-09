require 'sinatra'
require 'json'

helpers do
  def verify_signature(request_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], request_body)
    return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  end
end

get '/' do
  '<html><body><p>Hello</p></body></html>'
end

post '/payload' do
  request.body.rewind
  request_body = request.body.read
  verify_signature(request_body)
  push = JSON.parse(request_body)
  
  File.open('some_file.txt', 'w') do |f|
    f.write("JSON!!! #{push.inspect}")
  end

  {}.to_json
end
