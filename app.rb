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
  Thread.new do
    Dir.chdir('/home/minecraft/llmods') do
      `git clone #{repo['git_url']} >> /home/minecraft/public_html/log/thin.8080.log` unless File.directory?(repo['name'])
      Dir.chdir(repo['name']) do
        # TODO: Build and install the mod
        # TODO: Create simple log file that shows what happened in build
      end
    end
  end

  {}.to_json
end
