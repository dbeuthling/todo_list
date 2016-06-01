require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  if (1..100).cover? list_name.length
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "This list has been added successfully"
    redirect "/lists"
  else
    session[:error] = "The list name must be between 1 and 100 characters long."
    redirect "/lists/new"
  end
end