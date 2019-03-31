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
  # gives a str, the full path name upto the current folder
  @root = File.expand_path("..", __FILE__)
  # pulls all files from the data sub-folder
  @files = Dir.glob(@root + "/data/*").map {|file_path| File.basename(file_path)}
end

# helpers do
#   markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
# end

get '/' do
  erb :index
end

get '/:file_name' do
  if @files.include?(params[:file_name])
    file_path = @root + "/data/" + params[:file_name]

    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else
    session[:message] = "#{params[:file_name]} does not exist."
    redirect '/'
  end
end
