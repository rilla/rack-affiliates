module Rack
  #
  # Rack Middleware for extracting information from the request params and cookies.
  # It populates +env['affiliate.tag']+, # +env['affiliate.from']+ and
  # +env['affiliate.time'] if it detects a request came from an affiliated link 
  #
  class Affiliates

    def initialize(app, opts = {})
      @app = app
      @param = opts[:param] || "ref"
      @scope = opts[:scope] || "affiliate"
      @var_name = opts[:var_name] || "tag"
      @cookie_ttl = opts[:ttl] || 60*60*24*30  # 30 days
      @cookie_domain = opts[:domain] || nil
    end

    def call(env)
      req = Rack::Request.new(env)

      params_tag = req.params[@param]
      cookie_tag = req.cookies[cookie_var_name]

      if cookie_tag
        tag, from, time = cookie_info(req)
      end

      if params_tag && params_tag != cookie_tag
        tag, from, time = params_info(req)
      end

      if tag
        env["#{@scope}.#{@var_name}"] = tag
        env["#{@scope}.from"] = from
        env["#{@scope}.time"] = time
      end

      status, headers, body = @app.call(env)

      if tag != cookie_tag
        bake_cookies(headers, tag, from, time)
      end

      [status, headers, body]
    end

    def affiliate_info(req)
      params_info(req) || cookie_info(req) 
    end

    def params_info(req)
      [req.params[@param], req.env["HTTP_REFERER"], Time.now.to_i]
    end

    def cookie_info(req)
      [req.cookies[cookie_var_name], req.cookies[cookie_from_name], req.cookies[cookie_time_name].to_i] 
    end
    
    def cookie_prefix
      @scope[0..3]
    end

    def cookie_var_name
      "#{cookie_prefix}_#{@var_name}"
    end
    
    def cookie_from_name
      "#{cookie_prefix}_from"
    end    
    
    def cookie_time_name
      "#{cookie_prefix}_time"
    end

    protected
    def bake_cookies(headers, tag, from, time)
      expires = Time.now + @cookie_ttl
      { cookie_var_name => tag, 
        cookie_from_name => from, 
        cookie_time_name => time }.each do |key, value|
          cookie_hash = {:value => value, :expires => expires}
          cookie_hash[:domain] = @cookie_domain if @cookie_domain
          Rack::Utils.set_cookie_header!(headers, key, cookie_hash)
      end 
    end
  end
end
