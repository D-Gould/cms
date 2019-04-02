ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
    # post "/users/signin", username: "admin", password: "secret"
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get '/', username: "Admin", password: "secret"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_equal "text/html;charset=utf-8", last_response['Content-Type']
  end
  
  def test_file
    create_document "history.txt", "This is an important history file."

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal File.read(File.join(data_path, "/history.txt")), last_response.body
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

  def test_viewing_markdown_file
    create_document "dana.md", "Dana is the **best!**"
    get '/dana.md'

    assert_equal 200, last_response.status
    refute_includes last_response.body, "**best**"
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_edit_a_file
    create_document "history.txt", "old content"

    get '/'

    assert_includes last_response.body, "edit"

    get '/history.txt/edit'

    original_text = %w(File.read("data/history.txt"))

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Edit content of history.txt'
    assert_includes last_response.body, '<textarea'
    assert_includes last_response.body, "<input type=\"submit\""

    post '/history.txt', new_text: "new content"

    assert_equal 302, last_response.status
    get last_response['Location']
    assert_includes last_response.body, "history.txt has been updated"

    refute_equal original_text, File.read(File.join(data_path, "history.txt"))
  end

  def test_new_file_form
    get '/new'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Add a new document:'
    assert_includes last_response.body, "type=\"text\""
    assert_includes last_response.body, "<input type=\"submit\""
  end

  def test_submit_new_file
    post '/new', file_name: "new_file.txt"

    assert_equal 302, last_response.status
    get last_response['Location']
    assert_includes last_response.body, "new_file.txt was created"
    assert_includes last_response.body, "<a href=\"/new_file.txt\""
  end

  def test_submit_new_file_with_blank_name
    post '/new', file_name: ""

    assert_equal 422, last_response.status

  end

  def test_delete_a_file
    create_document("dana.txt")

    post '/dana.txt/delete'

    assert_equal 302, last_response.status

    get last_response['Location']
    assert_includes last_response.body, "dana.txt has been deleted"

    get '/'
    refute_includes last_response.body, "dana.txt"
  end

  # test/cms_test.rb
  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post "/users/signin", username: "Admin", password: "secret"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Welcome"
    assert_includes last_response.body, "Signed in as Admin"
  end

  def test_signin_with_bad_credentials
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_signout
    post "/users/signin", username: "Admin", password: "secret"
    get last_response["Location"]
    assert_includes last_response.body, "Welcome"

    post "/users/signout"
    get last_response["Location"]

    assert_includes last_response.body, "You have been signed out"
    assert_includes last_response.body, "Sign In"
  end
end
