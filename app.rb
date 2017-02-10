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
  erb :index
end

post '/payload' do
  request.body.rewind
  request_body = request.body.read
  verify_signature(request_body)
  repo = JSON.parse(request_body)['repository']

  return {}.to_json if repo['name'] == 'SMCI'
  
  # Now let's manage everything in a separate thread
  Thread.new do
    now = `date +%F_%H_%M`.strip
    output = "#{repo['name']}_build_log_#{now}.txt\n"
    
    Dir.chdir('/home/minecraft/llmods') do
      if File.directory?(repo['name'])
        Dir.chdir(repo['name']) { output += `git pull` + "\n" }
      else
        output += `git clone #{repo['git_url']}` + "\n"
      end
      
      Dir.chdir(repo['name']) do
        output += `mvn clean ; mvn package` + "\n"
        if File.directory?('target')
          Dir.chdir('target') do
            Dir['*.jar'].each do |jar|
              `cp #{jar} /home/minecraft/server/plugins`
              `/etc/init.d/minecraft command reload`
            end
          end
        end
      end
    end

    Dir.chdir('/home/minecraft/public_html/public')
    `mkdir #{repo['name']}` unless File.directory?(repo['name'])
    Dir.chdir(repo['name'])
    File.open("#{repo['name'].strip}_#{now.strip}.log", 'w') { |f| f.puts output }
    `rake restart`
  end

  {}.to_json
end
