require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
# require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:username] ||= nil
  session[:password] ||= nil
end

def render_markdown(path)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(File.read(path))
end

def render_plain_text(path)
  headers["Content-Type"] = "text/plain"
  File.read(path)
end

def load_file_content(file_path)
  file_type = File.extname(file_path)

  case file_type
  when ".md"
    erb render_markdown(file_path)
  else
    render_plain_text(file_path)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def proper_credentials?
  session[:username] == 'Admin' && session[:password] == 'secret'
end

get '/users/signin' do
  erb :signin
end

get '/' do
    pattern = File.join(data_path, "*")

    @files = Dir.glob(pattern).map {|file_path| File.basename(file_path)}
    erb :index, :layout => true
end

post '/users/signout' do
  session[:username] = nil
  session[:password] = nil
  session[:message] = "You have been signed out."
  redirect '/'
end

post '/users/signin' do
  session[:username] = params[:username]
  session[:password] = params[:password]
  if proper_credentials?
    session[:message] = "Welcome!"
    redirect '/'
  else
    session[:message] = "Invalid Credentials."
    status 422
    erb :signin
  end

end

get '/new' do
  erb :new
end

get '/:file_name' do
  file_path = File.join(data_path, params[:file_name])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)
  @content = File.read(file_path)

  erb :edit_file
end

post '/new' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  if file_name == ""
    session[:message] = "File name required."
    status 422
    erb :new
  else
    File.write(file_path, "")
    session[:message] = "#{file_name} was created."
    redirect '/'
  end
end

post '/:file_name/delete' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  File.delete(file_path)

  session[:message] = "#{file_name} has been deleted."
  redirect '/'
end

post '/:file_name' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  new_text = params[:new_text]
  File.write(file_path, new_text)

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end
