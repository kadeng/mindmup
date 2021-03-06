module MindMup
  module GithubRoutes
    configure do
      set :github_key, UUID.new.generate(:compact)
    end
    get '/github/login' do
      redirect "https://github.com/login/oauth/authorize?client_id=#{ENV["GITHUB_CLIENT_ID"]}&scope=repo&state=#{request.scheme}-#{settings.github_key}"
    end
    get '/github/postback' do
      if params[:state].nil?
        erb :github_response, :locals => { :response => {"error" => "Invalid response from Github" } }
        return
      end
      if params[:state].split('-')[0] == 'http' && request.scheme == 'https'
        redirect "#{settings.base_url.sub(/^https/,'http')}github/postback?#{request.query_string}"
        return
      end
      if params[:error]
        erb :github_response, :locals => { :response => {"error" => params[:error] } }
      elsif params[:code].nil?
        erb :github_response, :locals => { :response => {"error" => "Invalid response from Github" } }
      elsif (params[:state].split('-')[1] != settings.github_key) then
        redirect "/github/login"
      else
        begin
          uri = URI('https://github.com/login/oauth/access_token')
          https = Net::HTTP.start(uri.host, uri.port, :use_ssl=>uri.scheme =='https')
          response=https.post(uri.path, "client_id=#{ENV["GITHUB_CLIENT_ID"]}&client_secret=#{ENV["GITHUB_SECRET"]}&code=#{params[:code]}")
          unless response.code == "200"
            erb :github_response, :locals => { :response => {"error" => response.body } }
            return
          end
          tokens = Rack::Utils.parse_query response.body
          erb :github_response, :locals => { :response => tokens }
        rescue Exception
          erb :github_response, :locals => { :response => {"error" => "Network error" } }
        end
      end
    end
  end
end
