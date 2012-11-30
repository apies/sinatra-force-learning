class ForceToken < OAuth2::AccessToken
  def request(verb, path, opts={}, &block)
    response = super(verb, path, opts, &block)
    if response.status == 401 && refresh_token
      puts "Refreshing access token"
      @token = refresh!.token
      response = super(verb, path, opts, &block)
    end
    response
  end
end