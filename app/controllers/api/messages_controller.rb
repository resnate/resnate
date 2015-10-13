class API::MessagesController < ApplicationController
  include ActionController::HttpAuthentication::Token::ControllerMethods
  before_filter :restrict_access, :except => :userSearch
  def new
    @user = User.find(params[:user])
    @message = current_user.messages.new
  end
 
  def create
  	@recipients = []
  	attrs = params[:user].split(',').each do |attri|
  		@recipients.push(User.find(attri))
  	end

    @sender = params["sender_id"]
    
    User.find(@sender).send_message(@recipients, params[:body], params[:subject])
    @recipients.each do |recipient|
      Pusher.trigger('messages', 'inbox', {:message => recipient.id})
    end
  end

  def index
    userID = APIKey.find_by_access_token(params[:token]).user_id
    current_user = User.find(userID)
    @messages = []
    if current_user.mailbox.conversations.count == 0
    else
      conversations = current_user.mailbox.conversations
      conversations.each do |convo|
        @messages.push(message: { subject: convo.subject, created_at: convo.created_at })
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
