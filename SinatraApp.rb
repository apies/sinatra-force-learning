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
require './lib/asset_pack_default'
require './lib/ssl_on_thin'


class App < Sinatra::Base
  register Sinatra::AssetPackDefault
  register Sinatra::AssetPack
  register Sinatra::SSLOnThin
  use_asset_pack_defaults
  use Rack::Session::Cookie, :expire_after => 2592000
  set :root, File.dirname(__FILE__)
  
  set :client, OAuth2::Client.new(
    CONFIG['CONSUMER_KEY'], 
    CONFIG['CONSUMER_SECRET'],
    :site => 'https://login.salesforce.com',
    :authorize_url => '/services/oauth2/authorize',
    :token_url => '/services/oauth2/token'  
  )


  

  before do
    pass if request.path_info == '/auth/salesforce/callback' 
    if session[:access_token]
      @access_token = ForceToken.from_hash(App.client, { :access_token => session[:access_token], :refresh_token =>  session[:refresh_token], :header_format => 'OAuth %s' } )
      @instance_url = session[:instance_url]
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

  get '/logout' do
    @access_token.get("http://login.salesforce.com/services/oauth2/revoke?token=#{session[:access_token]}")
    @logout_url = "#{session[:instance_url]}/secur/logout.jsp"
    # Clean up the session
    session[:access_token] = nil
    session[:instance_url] = nil
    session[:field_list] = nil
    redirect '/'
  end

  get '/auth/salesforce/callback' do
    access_token = App.client.auth_code.get_token(params[:code], :redirect_uri => "https://localhost:3000/auth/salesforce/callback")
    session[:access_token]  = access_token.token
    session[:refresh_token] = access_token.refresh_token
    session[:instance_url]  = access_token.params['instance_url']
    @access_token = ForceToken.from_hash(App.client, { :access_token => access_token.token, :refresh_token =>  access_token.refresh_token, :header_format => 'OAuth %s' } )
    redirect '/'
  end


  get '/' do
    query = 'SELECT Name, Id FROM Account'
    #@accounts = @access_token.get("#{@instance_url}/services/data/v26.0/query/?q=#{CGI::escape(query)}").parsed
    soql = "SELECT Consultant__c, Client__c, Client_Manager__c from Placement__c"
    #@placements = @access_token.get("#{@instance_url}/services/data/v26.0/query/?q=#{CGI::escape(soql)}").parsed
    erb :index
  end

  get '/query' do
    soql = "SELECT Consultant__c, Client__c, Client_Manager__c from Placement__c"
    @placements = @access_token.get("#{@instance_url}/services/data/v26.0/query/?q=#{CGI::escape(soql)}").parsed
    @placements.to_json
  end

  
  
  #run!

end

