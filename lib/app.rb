require 'sinatra'
require 'redis'
require 'cf-app-utils'
require 'json'
require 'net/http'

before do
  unless redis_credentials
    halt(500, %{
You must bind a Redis service instance to this application.

You can run the following commands to create an instance and bind to it:

  $ cf create-service p-redis development redis-instance
  $ cf bind-service <app-name> redis-instance})
  end
end

get '/' do
  settings.requests += 1
  app_info = ENV['VCAP_APPLICATION'] ? JSON.parse(ENV['VCAP_APPLICATION']) : Hash.new
  ENV['APP_NAME'] = app_info["application_name"]
  ENV['APP_INSTANCE'] = app_info["instance_index"].to_s
  ENV['APP_MEM'] = app_info["limits"] ? app_info["limits"]["mem"].to_s : " "
  ENV['APP_DISK'] = app_info["limits"] ? app_info["limits"]["disk"].to_s : " "
  ENV['APP_IP'] = IPSocket.getaddress(Socket.gethostname)
  ENV['APP_PORT'] = app_info["port"].to_s
  ENV['SERVICE_JSON'] = JSON.pretty_generate(JSON.parse(ENV['VCAP_SERVICES']))
  erb :'index'
end

get '/killSwitch' do
  Kernel.exit!
end

get '/load' do
   i = 0
   myStr = "Kill the CPU!!!"
   buff = ""

  while i < 50000  do
    buff += myStr.to_s
    buff.reverse!
    i += 1
  end
  settings.requests += 1
  "<h2>I'm healthy!</h2>"
end

get '/health' do
  settings.requests += 1
  "<h2>I'm healthy!</h2>"
end

put '/:key' do
  data = params[:data]
  if data
    redis_client.set(params[:key], data)
    status 201
    body 'success'
  else
    status 400
    body 'data field missing'
  end
end

get '/:key' do
  value = redis_client.get(params[:key])
  if value
    status 200
    body value
  else
    status 404
    body 'key not present'
  end
end

get '/config/:item' do
  unless params[:item]
    status 400
    body 'USAGE: GET /config/:item'
    return
  end

  value = redis_client.config('get', params[:item])
  if value.length < 2
    status 404
    body "config item #{params[:item]} not found"
    return
  end

  status 200
  body value[1]
end

delete '/:key' do
  result = redis_client.del(params[:key])
  if result > 0
    status 200
    body 'success'
  else
    status 404
    body 'key not present'
  end
end

def redis_credentials
  if ENV['VCAP_SERVICES']
    all_pivotal_redis_credentials = CF::App::Credentials.find_all_by_all_service_tags(['redis', 'pivotal'])
    all_pivotal_redis_credentials && all_pivotal_redis_credentials.first
  end
end

def redis_client
  @client ||= Redis.new(
    host: redis_credentials.fetch('host'),
    port: redis_credentials.fetch('port'),
    password: redis_credentials.fetch('password')
  )
end
