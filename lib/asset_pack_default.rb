require 'sinatra/base'
require 'sinatra/assetpack'

class AssetPackDefault < Sinatra::Base

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
end