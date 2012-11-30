require 'sinatra/base'
require 'sinatra/assetpack'
require 'sass'
require 'coffee_script'
require 'yaml'
require 'oauth2'
require 'json'
require 'multi_json'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'pry'

CONFIG = YAML.load(File.read(File.expand_path('./config/application.yml')))
require './app_models'
require './lib/asset_pack_default.rb'


class App < Sinatra::Base


  
  use Rack::Session::Cookie
  set :root, File.dirname(__FILE__)
  set :client, OAuth2::Client.new(
    CONFIG['CONSUMER_KEY'], 
    CONFIG['CONSUMER_SECRET'],
    :site => 'https://login.salesforce.com',
    :authorize_url => '/services/oauth2/authorize',
    :token_url => '/services/oauth2/token'  
  )

  register Sinatra::AssetPack




  assets {
    serve '/js',     from: 'app/js'        # Optional
    serve '/css',    from: 'app/css'       # Optional
    serve '/images', from: 'app/images'    # Optional

    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    js :app, '/js/app.js', [
      '/js/vendor/**/*.js',
      '/js/app/**/*.js'
    ]

    css :application, '/css/application.css', [
      '/css/screen.css'
    ]

    js_compression  :jsmin      # Optional
    css_compression :sass       # Optional
  }

  rack_handler_config = {}
    ssl_options = {
      :private_key_file => '/ssl_keys/server.key',
      :cert_chain_file => '/ssl_keys/server.crt',
      :verify_peer => false,
    }

  #use OmniAuth::Strategies::Forcedotcom #CONFIG['CONSUMER_KEY'], CONFIG['CONSUMER_SECRET']
  set :ssl, true

  def self.run!
    rack_handler_config = {}
    ssl_options = {
      :private_key_file => '/ssl_keys/server.key',
      :cert_chain_file => '/ssl_keys/server.crt',
      :verify_peer => false,
    }
    Rack::Handler::Thin.run(self, rack_handler_config) do |server|
      server.ssl = true
      server.ssl_options = ssl_options
    end
  end




  post '/authenticate' do
    environment = params[:options]
    redirect App.client.auth_code.authorize_url( 
      
      :redirect_uri => "https://localhost:3000/auth/salesforce/callback", 
      :display => "page",
      :immediate => "false",
      :scope => "api id refresh_token"
    )
  end

  get '/auth/salesforce/callback' do
    #params.to_s
    access_token = App.client.auth_code.get_token(params[:code], :redirect_uri => "https://localhost:3000/auth/salesforce/callback")
    session['access_token']  = access_token.token
    session['refresh_token'] = access_token.refresh_token
    session['instance_url']  = access_token.params['instance_url']
    session

  end


  get '/' do
    erb :index
  end

  
  
  #run!

end

