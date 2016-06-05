require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def all_done?(list)
    unchecked_todos(list) == 0 && list[:todos].length > 0
  end

  def list_class(list)
    "complete" if all_done?(list)
  end

  def unchecked_todos(list)
    list[:todos].count {|todo| todo[:completed] == false}
  end

  def todos_count(list)
    list[:todos].size
  end
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

# View a single list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# Edit existing list
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :list_edit, layout: :layout
end

#Update existing list
post "/lists/:id/edit" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @id = params[:id].to_i
  @list = session[:lists][@id]

  if error
    session[:error] = error
    erb :list_edit, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "This list has been edited successfully"
    redirect "/lists/#{@id}"
  end
end

# Delete list
post "/lists/:id/destroy" do
id = params[:id].to_i
session[:lists].slice!(id)
session[:success] = "The list has been deleted"
redirect "/lists"
end

# Error message if invalid todo
def error_for_todo(todo)
  if !(1..100).cover? todo.length
    "The todo must be between 1 and 100 characters."
  end
end

# Add todos to list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo item
post "/lists/:list_id/todos/:todo_id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# Mark todo as completed or uncomplete
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The list has been updated."
  redirect "lists/#{@list_id}"
end

# Mark all todos complete on a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  @list[:todos].each {|todo| todo[:completed] = true}
  session[:success] = "All todos have been completed."
  redirect "lists/#{@list_id}"
end