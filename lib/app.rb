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
  $ cf create-service rediscloud 30mb redis-instance
  $ cf bind-service <app-name> redis-instance})
  end
end

get '/' do
  app_info = ENV['VCAP_APPLICATION'] ? JSON.parse(ENV['VCAP_APPLICATION']) : Hash.new
  ENV['APP_NAME'] = app_info["application_name"]
  ENV['APP_INSTANCE'] = app_info["instance_index"].to_s
  ENV['APP_MEM'] = app_info["limits"] ? app_info["limits"]["mem"].to_s : " "
  ENV['APP_DISK'] = app_info["limits"] ? app_info["limits"]["disk"].to_s : " "
  ENV['APP_IP'] = IPSocket.getaddress(Socket.gethostname)
  ENV['APP_PORT'] = app_info["port"].to_s
  ENV['REDIS_CREDENTIALS'] = redis_credentials.to_s
  ENV['SERVICE_JSON'] = JSON.pretty_generate(JSON.parse(ENV['VCAP_SERVICES']))
  erb :'index'
end

get '/redisUI' do
  REDIS = Hash.new
  keys = redis_client.keys('*')
  keys.each do |key|
    REDIS[key] = redis_client.get(key)
  end
  erb :'redisui'
end

get '/killSwitch' do
  Kernel.exit!
end

put '/store/:key' do
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

get '/store/:key' do
  value = redis_client.get(params[:key])
  if value
    status 200
    body value
  else
    status 404
    body 'key not present'
  end
end

delete '/store/:key' do
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
    all_pivotal_redis_credentials = CF::App::Credentials.find_by_service_name('redis-instance')
    all_pivotal_redis_credentials
  end
end

def redis_client
  @client ||= Redis.new(
    host: redis_credentials.fetch('host'),
    port: redis_credentials.fetch('port'),
    password: redis_credentials.fetch('password')
  )
end
