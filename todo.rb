require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
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

  def sort_lists(lists, &block)

    complete_lists, incomplete_lists = lists.partition { |list| all_done?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

def next_element_id(elements)
  ids = []
  elements.each { |element| ids << element[:id] }
  ids.empty? ? 1 : ids.max + 1
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

# Redirect to list of lists if list index doesn't exist
def load_list(id)
    list = session[:lists].find { |list| list[:id] == id }
    return list if list

    session[:error] = "The specified list was not found."
    redirect "/lists"
    halt
  end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_element_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
    session[:success] = "This list has been added successfully"
    redirect "/lists"
  end
end

# View a single list of todos
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  erb :list, layout: :layout
end

# Edit existing list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = load_list(id)
  erb :list_edit, layout: :layout
end

#Update existing list
post "/lists/:id/edit" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  id = params[:id].to_i
  @list = load_list(id)

  if error
    session[:error] = error
    erb :list_edit, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "This list has been edited successfully"
    redirect "/lists/#{id}"
  end
end

# Delete list
post "/lists/:id/destroy" do
  list_id = params[:id].to_i
  session[:lists].reject! { |list| list[:id] == list_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted"
    redirect "/lists"
  end
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
  @list = load_list(@list_id)
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_element_id(@list[:todos])
    @list[:todos] << {id: id, name: text, completed: false}
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo item
post "/lists/:list_id/todos/:todo_id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id}
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Mark todo as completed or incomplete
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:todo_id].to_i
  todo = @list[:todos].find { |todo| todo[:id] == todo_id}
  is_completed = params[:completed] == "true"

  todo[:completed] = is_completed
  session[:success] = "The list has been updated."
  redirect "lists/#{@list_id}"
end

# Mark all todos complete on a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @list[:todos].each {|todo| todo[:completed] = true}
  session[:success] = "All todos have been completed."
  redirect "lists/#{@list_id}"
end