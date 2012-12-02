require 'sinatra/base'
module Sinatra
	module SSLOnThin
		#def use_ssl_defaults
		#end

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

	end
	register SSLOnThin
end