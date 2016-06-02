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

# Return an error message if invalid. Otherwise nil.
def error_for_list_name(name)
  if session[:lists].any? { |list| list[:name] == name }
    "The list name must be unique."
  elsif !(1..100).cover? name.length
    "The list name must be between 1 and 100 characters."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "This list has been added successfully"
    redirect "/lists"
  end
end

get "/lists/:id" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :list, layout: :layout
end
