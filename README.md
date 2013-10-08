Rack::Affiliates
================

Rack::Affiliates is a rack middleware that extracts information about the referrals came from an affiliated site. Specifically, it looks up for specific parameter (<code>ref</code> by default) in the request. If found, it persists affiliate tag, referring url and time in a cookie for later use.

This fork
---------

Allows using multiple instances of the middleware to track different parameters by adding two new configuration options: <code>:scope</code> and <code>:var_name</code>.

Therefore, initializing the middleware like this:

    # Rails 3 App - in config/application.rb
    config.middleware.use Rack::Affiliates, { :scope => 'referrer', :var_name => 'referral', :param => 'ref', :ttl => 6.months }
    config.middleware.use Rack::Affiliates, { :scope => 'utm', :var_name => 'source', :param => 'utm_source', :ttl => 6.months }
    config.middleware.use Rack::Affiliates, { :scope => 'utm', :var_name => 'campaign', :param => 'utm_campaign', :ttl => 6.months }
    config.middleware.use Rack::Affiliates, { :scope => 'utm', :var_name => 'medium', :param => 'utm_medium', :ttl => 6.months }

Allows for something like this in your controller:

    @referral = request.env['referrer.referral']
    @referral_time = request.env['referrer.time']
    @utm_source = request.env['utm.source'] if request.env['utm.source']
    @utm_medium = request.env['utm.medium'] if request.env['utm.medium']
    @utm_campaign = request.env['utm.campaign'] if request.env['utm.campaign']
    

Common Scenario
---------------

Affiliate links tracking is very common task if you want to promote your online business. This middleware helps you to do that.

1. You associate an affiliate tag (for eg. <code>ABC123</code>) with your partner.
2. The affiliate promotes your business at http://partner.org by linking to your site with like <code>http://yoursite.org?ref=ABC123</code>.
3. A user clicks through the link and lands on your site.
4. Rack::Affiliates middleware finds <code>ref</code> parameter in the request, extracts affiliate tag and saves it in a cookie
5. User signs up (now or later) and you mark it as a referral from your partner
6. PROFIT!

Installation
------------

In your Gemfile:

    gem 'rack-affiliates', :git => 'git@github.com:rilla/rack-affiliates.git'


Rails 3 Example Usage
---------------------

Add the middleware to your application stack:

    # Rails 3 App - in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Affiliates
      ...
    end
    
    # Rails 2 App - in config/environment.rb
    Rails::Initializer.run do |config|
      ...
      config.middleware.use "Rack::Affiliates"
      ...
    end

Now you can check any request to see who came to your site via an affiliated link and use this information in your application. Affiliate tag is saved in the cookie and will come into play if user returns to your site later.

    class ExampleController < ApplicationController
      def index
        str = if request.env['affiliate.tag] && affiliate = User.find_by_affiliate_tag(request.env['affiliate.tag'])
          "Halo, referral! You've been referred here by #{affiliate.name} from #{request.env['affiliate.from']} @ #{Time.at(env['affiliate.time'])}"
        else
          "We're glad you found us on your own!"
        end
        
        render :text => str
      end
    end


Customization
-------------

You can customize parameter name by providing <code>:param</code> option (default is <code>ref</code>).
By default cookie is set for 30 days, you can extend time to live with <code>:ttl</code> option (default is 30 days). 

    #Rails 3 in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Affiliates, {:param => 'aff_id', :ttl => 3.months}
      ...
    end

The <code>:domain</code> option allows to customize cookie domain. 

    #Rails 3 in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Affiliates, :domain => '.example.org'
      ...
    end

Middleware will set cookie on <code>.example.org</code> so it's accessible on <code>www.example.org</code>, <code>app.example.org</code> etc.

Credits
=======

Thanks goes to Rack::Referrals (https://github.com/deviantech/rack-referrals) for the inspiration.

