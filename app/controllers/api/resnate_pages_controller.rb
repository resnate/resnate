class API::UsersController < ApplicationController
  	include ActionController::HttpAuthentication::Token::ControllerMethods
	before_filter :restrict_access, :except => :userSearch

	def AmazonStore
    	if current_user.country == "United Kingdom"
      		req = Vacuum.new('GB', true)
    	elsif current_user.country == "France"
      		req = Vacuum.new('FR', true)
    	else
      		req = Vacuum.new('US', true)
    	end
    	search_query = params[:search_query]
  		req.associate_tag = 'resnate-21'
            req.configure(   aws_access_key_id:     'AKIAIK5DPVPX6A2SKBSQ',aws_secret_access_key: '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', associate_tag: 'resnate-21')
             params = {'SearchIndex' => 'Apparel', 'Keywords'    => search_query, 'ResponseGroup' => 'ItemAttributes, Offers, Images', 'Availability' => "Available", 'Condition' => "All", 'ItemPage' => 1} 
             res = req.item_search(params)
             hash = res.to_h
             items = hash["ItemSearchResponse"]["Items"]["Item"]
             noOfItems = Integer(hash["ItemSearchResponse"]["Items"]["TotalResults"])
             if noOfItems == 0
              @results = nil
             else
             	@results = []
              items.take(3).each do |i|
                if i["LargeImage"].nil?
                  next
                else
                  @results.push :image => 'https://d1ge0kk1l5kms0.cloudfront.net/images/I/' + i["LargeImage"]["URL"][38..-1], :link => i["DetailPageURL"].insert(4, 'S')
					
                end
            end
        end
  	end

	private
      def restrict_access
        authenticate_or_request_with_http_token do |token, options|
          APIKey.exists?(access_token: token)
        end

        def request_http_token_authentication(realm = "Application")  
          self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
          self.__send__ :render, :json => { :error => "HTTP Token: Access denied. You did not provide an valid API key." }.to_json, :status => :unauthorized
        end
      end
end