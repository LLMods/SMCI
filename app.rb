require 'sinatra'
require 'json'
require 'yaml'

helpers do
  def verify_signature(request_body)
    token = YAML.load_file('.secret.yml')['secret']
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, request_body)
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
  repo = JSON.parse(request_body)['repository']

  # Now let's manage everything in a separate thread
  

  {}.to_json
end
