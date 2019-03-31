require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
# require 'sinatra/content_for'


before do
  @files = Dir.entries("data").reject {|file| file.match?(/\A\./)}
end

get '/' do
  erb :index
end
