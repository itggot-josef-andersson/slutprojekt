require 'json'

class App < Sinatra::Base
  enable :sessions


  # Logged in users can go anywhere on the
  # site, guests can only view the homepage '/'.
  # We do not need to fetch the user from the
  # database on requests starting with '/res'.
  before /^(?!(\/res\/)|(\/favicon.ico))/ do
    @user = User.first(:id => session[:user_id])
    if request.path_info != '/login' && request.path_info != '/'
      if !@user
        # If a guest tries to access a restricted page
        # they are redirected to the login page.
        session[:redirect] = request.path_info
        redirect '/login'
      else
        # If the user is to be refered anywhere, they
        # will have a cookie called refer containing the path.
        if session[:redirect] && session[:redirect].length > 0
          ref = session[:redirect]
          session[:redirect] = nil
          redirect ref
        end
      end
    end
  end



  # The sites home page will contain a list of the
  # latest information posts that has been posted
  # by the administrators.
  get '/?' do
    @information = Information.all(:limit => 20, :order => [ :uploaded.desc ]) # We limit to 20 posts as of now
  	slim :home
  end



  # This page will prompt the user to login
  # using their google account. (Temporarily
  # username + password instead) If the user
  # is already logged in, they are redirected
  # to their user page.
  get '/login/?' do
    if @user
      redirect '/me'
    else
      slim :'account/login'
    end
  end



  # When someone is trying to login, they send
  # a POST request to '/login'. If the credentials
  # are correct and they are allowed to sign in,
  # they are signed in and redirected to the last
  # page they where on or their user page. The POST
  # request needs a username and a password parameter.
  post '/login/?' do
    if !@user
      if params[:username].length > 0 && params[:password].length > 0
        user = User.first(:username => params[:username])
        if user && user.password == params[:password]
          # The user posted the correct credentials and they
          # are now being signed in by storing their user_id
          # in their session. They are then redirected to their
          # user's page.
          session[:user_id] = user.id
          redirect "/#{user.id}/info"
        else
          redirect '/login#wrong_credentials' # The client tried to sign in with either the wrong username or password
        end
      else
        redirect '/login#missing_parameters' # The user did not fill in the whole form
      end
    else
      redirect '/me' # If the user is already sign in they are just redirected to their user page
    end
  end


  # To logout from the page, a logged in user can
  # visit the '/logout' page. To logout an  user we
  # simply destroy the user_id in their session.
  get '/logout/?' do
    session[:user_id] = nil
    redirect '/'
  end



  # A user can view their own information and list their
  # tickets from their user page. ('/<uid>/info') From here a user
  # will also be able to manage all their tickets at once. Admins
  # can also view others user info.
  get '/:user_id/info/?' do
    @target_user = User.first(:id => params[:user_id])
    if @target_user
      if @target_user.id == @user.id || @user.admin?
        slim :'account/info'
      else
        redirect '/#not_allowed'
      end
    else
      redirect '/#invalid_user'
    end
  end



  # To list all the frequently asked questions a user
  # can visit the FAQ page.
  get '/faq/?' do
    @categories = Category.all
    @answers = Answer.all
    slim :faq
  end



  # To view a specific frequently asked question a user
  # can visit the page '/faq/<answer_id>'.
  get '/faq/:answer_id/?' do
    @answer = Answer.first(:id => params[:answer_id])
    if @answer
      slim :view_faq
    else
      redirect '/faq#invalid_id'
    end
  end



  # To submit a ticket (ask a question) a user can visit
  # the '/ask' page.
  get '/ask/?' do
    @categories = Category.all
    slim :'tickets/ask'
  end



  # When a user is submitting a ticket (asking a question),
  # they will POST it to '/ask'. The POST request needs
  # the parameters title, category and description.
  post '/ask/?' do
    category = Category.first(:id => params[:category])
    if params[:title].length > 0 && params[:description].length > 0 && category
      ticket = Ticket.create(
          :title => params[:title],
          :description => params[:description],
          :category => category,
          :user => @user)
      if ticket
        # The ticket was successfully created and the client is redirected to the page of their ticket
        redirect "/#{@user.id}/tickets/#{ticket.id}"
      else
        # Something went wrong when creating the ticket
        redirect '/ask#something_went_wrong'
      end
    else
      redirect '/ask#missing_parameters'
    end
  end



  # To look at tickets you visit '/<user_id>/tickets/[ticket_id]'
  # where the ticket_id is optional. If a ticket_id is provided
  # the ticket thread will be displayed, else, a list of tickets
  # by specified user will be displayed.
  get '/:user_id/tickets/?:ticket_id?/?' do
    if params[:user_id]
      # Get the user object that the client wants to view
      @target_user = User.first(:id => params[:user_id])
      if @target_user && @target_user.id == @user.id || @user.admin?
        # The client is allowed to view the tickets of target_user
        if params[:ticket_id]
          # The client has specified a specific ticket_id to view
          @ticket = Ticket.first(:id => params[:ticket_id])
          if @ticket
            # The specified ticket exists
            @posts = Post.all(:ticket_id => @ticket.id, :limit => 40, :order => [ :created.asc ])
            slim :'tickets/ticket'
          else
            # The specified ticket does not exist
            redirect "/#{params[:user_id]}/tickets#invalid_ticket"
          end
        else
          # The client did not specify a specific ticket_id, instead we will display a list of tickets by target_user
          @tickets = Ticket.all(:user_id => @target_user.id, :limit => 40, :order => [ :created.desc ])
          slim :'tickets/ticket_list'
        end
      else
        # The client is trying to view somebody else's tickets when they are not allowed to
        redirect '/#not_allowed'
      end
    else
      # This should never happen
      redirect '/#what_happened'
    end
  end



  # When a user is commenting on a ticket they send a
  # POST request here. The POST needs a 'comment' parameter.
  post '/:user_id/tickets/:ticket_id/comment/?' do
    if params[:comment].length > 0
      ticket = Ticket.first(:id => params[:ticket_id])
      if ticket
        if !ticket.closed?
          # The ticket is not closed, posting therefore is allowed
          if ticket.user_id == @user.id || @user.admin?
            # The user is allowed to comment on the ticket
            post = Post.create(:text => params[:comment], :user => @user, :ticket => ticket)
            redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#pid_#{post.id}" # The comment was successfully posted
          else
            # The user is not allowed to comment on the ticket
            redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#not_allowed"
          end
        else
          # The ticket is closed and no new posts can be made on it
          redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#ticket_is_closed"
        end
      else
        # The ticket was not found, which is strange. I guess this can
        # occur if a user is trying to comment on a ticket after it was removed.
        redirect "/#{params[:user_id]}/tickets#invalid_ticket"
      end
    else
      redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#missing_parameters"
    end
  end



  # If a user wants to remove a comment they use this. Nice.
  get '/:user_id/tickets/:ticket_id/comment/remove/:post_id' do
    ticket = Ticket.first(:id => params[:ticket_id])
    if ticket
      if !ticket.closed?
        # The ticket is not closed, posting therefore is allowed
        if ticket.user_id == @user.id || @user.admin?
          # The user is allowed to remove the comment
          post = Post.first(:id => params[:post_id])
          if post
            # The specified post is a valid post
            post.destroy
            redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#removed_post" # The comment was successfully posted
          else
            # The post id was invalid
            redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}#invalid_post"
          end
        else
          # The user is not allowed to comment on the ticket
          redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#not_allowed"
        end
      else
        # The ticket is closed and no new posts can be made on it
        redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#ticket_is_closed"
      end
    else
      # The ticket was not found, which is strange. I guess this can
      # occur if a user is trying to comment on a ticket after it was removed.
      redirect "/#{params[:user_id]}/tickets#invalid_ticket"
    end
  end


  # To close a ticket, a GET request is sent to
  # /<user_id>/tickets/<ticket_id>/close.
  get '/:user_id/tickets/:ticket_id/close/?' do
    ticket = Ticket.first(:id => params[:ticket_id])
    if ticket
      # The ticket exists
      if !ticket.closed?
        # The ticket is not closed, and will now be closed
        if ticket.user_id == @user.id || @user.admin?
          # The user is allowed to close the ticket
          ticket.update(:status => 'closed')
          redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#closed_ticket"
        else
          # The user is not allowed to close the ticket
          redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#not_allowed"
        end
      else
        # The ticket is already closed
        redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#closed_ticket"
      end
    else
      # The ticket was not found
      redirect "/#{params[:user_id]}/tickets#invalid_ticket"
    end
  end



  # To re-open a ticket, a GET request is sent to
  # /<user_id>/tickets/<ticket_id>/open
  get '/:user_id/tickets/:ticket_id/open/?' do
    ticket = Ticket.first(:id => params[:ticket_id])
    if ticket
      # The ticket exists
      if ticket.closed?
        # The ticket is closed, and will now be opened
        if ticket.user_id == @user.id || @user.admin?
          # The user is allowed to open the ticket
          ticket.update(:status => 'open')
          redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#opened_ticket"
        else
          # The user is not allowed to open the ticket
          redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#not_allowed"
        end
      else
        # The ticket is already open
        redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#opened_ticket"
      end
    else
      # The ticket was not found
      redirect "/#{params[:user_id]}/tickets#invalid_ticket"
    end
  end



  # To delete a ticket, a GET request is sent to
  # /<user_id>/tickets/<ticket_id>/remove
  get '/:user_id/tickets/:ticket_id/remove/?' do
    ticket = Ticket.first(:id => params[:ticket_id])
    if ticket
      # The ticket exists
      if ticket.user_id == @user.id || @user.admin?
        # The user is allowed to remove the ticket
        ticket.posts.destroy  # Remove all posts on the ticket
        ticket.destroy        # Remove the ticket itself
        redirect "/#{params[:user_id]}/tickets#removed_ticket"
      else
        # The user is not allowed to open the ticket
        redirect "/#{params[:user_id]}/tickets/#{params[:ticket_id]}/#not_allowed"
      end
    else
      # The ticket was not found
      redirect "/#{params[:user_id]}/tickets#invalid_ticket"
    end
  end



  ## THE ADMINISTRATION PAGES ##

  # Only administrators are allowed to visit
  # the admin pages
  before '/admin/?*' do
    unless @user.admin?
      redirect '/'
    end
  end


  # Users with administration rights will be
  # able to visit the admin page to see admin options
  get '/admin/?' do
    slim :'admin/admin'
  end


  # When tickets are being listed we go through this controller
  # to sort the list of tickets according to passed GET parameters.
  before '/admin/view/tickets/*/?' do
    sort_options = %w(created user_id title status category_id)
    sort_by = params[:sort_by]
    sort_order = params[:sort_order]
    if sort_options.include? sort_by
      # User wants to sort by a valid sort option
      if sort_order == 'desc'
        # User wants to sort by descending
        @sort_order = [ :"#{sort_by}".desc ]
      else
        # User wants to sort by ascending
        @sort_order = [ :"#{sort_by}".asc ]
      end
    else
      # User tried to sort by something that we cannot sort by
    end
  end


  # To upload a new Q&A, an admin sends a POST requst here
  # with the parameters question, answer and category.
  post '/admin/faq/add/?' do
    p params[:answer].gsub("\n", '<br>')
    category = Category.first(:id => params[:category])
    if params[:question] && params[:answer] && params[:question].length > 0 && params[:answer].length > 0 && category
      answer = Answer.create(:question => params[:question], :answer => params[:answer].gsub("\n", '<br>').gsub("\r", ''), :category => category)
      answer.save
      redirect "/faq/#{answer.id}" # The Q&A was uploaded successfully
    else
      redirect '/faq#missing_parameters'
    end
  end


  # List all tickets by creation date
  get '/admin/view/tickets/all/?' do
    @tickets = Ticket.all(:order => @sort_order)
    slim :'admin/list_tickets'
  end

  # List all tickets that are open by creation date
  get '/admin/view/tickets/unseen/?' do
    @tickets = Ticket.all(:status => 'unseen', :order => @sort_order)
    slim :'admin/list_tickets'
  end

  # List all tickets that are open by creation date
  get '/admin/view/tickets/seen/?' do
    @tickets = Ticket.all(:status => 'seen', :order => @sort_order)
    slim :'admin/list_tickets'
  end


  # List all users by name
  get '/admin/view/users/all/?' do
    @users = User.all(:order => [ :name.asc ])
    slim :'admin/list_users'
  end

  # List all administrators by name
  get '/admin/view/users/administrators/?' do
    @users = User.all(:admin => true, :order => [ :name.asc ])
    slim :'admin/list_users'
  end




  # All api responses are in JSON.
  before '/api/*' do
    content_type 'application/json; charset=utf-8'
  end


  # Returns the answer and question to a FAQ in JSON.
  get '/api/faq/?' do
    answer = Answer.first(:id => params[:answer_id])
    if answer
      { :id => answer.id, :question => answer.question, :answer => answer.answer }.to_json
    else
      { :error => 'invalid_id' }.to_json
    end
  end


end