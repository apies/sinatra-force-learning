require 'sinatra/base'
require 'sinatra/assetpack'
require 'sass'
require 'coffee_script'
require 'yaml'
require 'oauth2'
require 'json'
require 'multi_json'
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

    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    js :app, '/js/app.js', [
      '/js/vendor/**/*.js',
      '/js/app/**/*.js'
    ]
    css_compression :sass       # Optional
  }

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

  before do
    pass if request.path_info == '/auth/salesforce/callback'
    token  = session[:access_token]
    refresh = session[:refresh_token]
    @instance_url = session[:instance_url]
    if token
      @access_token = ForceToken.from_hash(App.client, { :access_token => token, :refresh_token =>  refresh, :header_format => 'OAuth %s' } )
    else
      redirect App.client.auth_code.authorize_url("https://localhost:3000/auth/salesforce/callback")
    end
  end

  after do
    if @access_token && session[:access_token] != @access_token.token
      puts "refreshing token"
      session[:access_token] = @access_token.token
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
    access_token = App.client.auth_code.get_token(params[:code], :redirect_uri => "https://localhost:3000/auth/salesforce/callback")
    session[:access_token]  = access_token.token
    session[:refresh_token] = access_token.refresh_token
    session[:instance_url]  = access_token.params['instance_url']
    redirect '/'
  end


  get '/' do
    query = 'SELECT Name, Id FROM Account'
    @accounts = @access_token.get("#{@instance_url}/services/data/v26.0/query/?q=#{CGI::escape(query)}").parsed
    soql = "SELECT Consultant__c, Client__c, Client_Manager__c from Placement__c"
    @placements = @access_token.get("#{@instance_url}/services/data/v26.0/query/?q=#{CGI::escape(soql)}").parsed
    erb :index
  end

  
  
  #run!

end

