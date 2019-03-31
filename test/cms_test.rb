ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "changes.txt"
    assert_equal "text/html;charset=utf-8", last_response['Content-Type']
  end

  def test_file
    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal File.read("data/history.txt"), last_response.body
    assert_equal "text/plain", last_response["Content-Type"]

  end

  def test_document_not_found
    get '/pat.txt'

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "pat.txt does not exist"

    get '/'

    refute_includes last_response.body, "pat.txt does not exist"
  end

  def test_markdown_file
    get '/dana.md'

    assert_equal 200, last_response.status
    refute_includes last_resoonse.body, "**bold**"
    assert_equal "text/html", last_response["Content-Type"]
  end

end