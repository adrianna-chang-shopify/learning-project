### Require dependencies
require 'cgi'
require 'rack/handler/puma'
require 'rack'
require 'sqlite3'

# Struct to define what a Blog looks like
Blog = Struct.new(:title, :content, keyword_init: true)

SEED_BLOGS = [
  Blog.new(title: 'My awesome blog!', content: 'my favourite HTML tags are <p> and <script>'),
  Blog.new(title: 'Another cool blog!', content: 'my favourite HTML tags are <br> and <hr>')
]

# Create or open SQLite database
database = SQLite3::Database.new('application.sqlite3', results_as_hash: true)

# Check if we need to create our table
existing_tables = database.execute('SELECT name FROM sqlite_master WHERE type="table";')
unless existing_tables.include?({ 'name' => 'blogs'})
  database.execute('CREATE TABLE blogs (title VARCHAR(30), content TEXT);')
end

# Alternative
# table_exists = database.get_first_value('SELECT COUNT(*) FROM sqlite_master WHERE type="table" AND name="blogs";')
# if table_exists == 0
#   database.execute('CREATE TABLE blogs (title VARCHAR(30), content TEXT);')
# end

# Seed some blog data if none exists already
if database.get_first_value('SELECT COUNT(*) FROM blogs;') == 0
  SEED_BLOGS.each do |blog|
    database.execute('INSERT INTO blogs (title, content) VALUES (?, ?)', [blog.title, blog.content])
  end
end

app = lambda { |environment|
  puts 'Rack app got a request!'
  # Build Rack request
  request = Rack::Request.new(environment)

  # Build Rack response
  response = Rack::Response.new

  if request.get? && request.path == '/show-data'
    response.content_type = 'text/html'
    response.finish do
      response.write '<ul>'
      blogs = database.execute('SELECT * FROM blogs;').map { |data| Blog.new(data) }
      blogs.each do |blog|
        response.write '<li>'
        response.write "<strong>Title: #{CGI.escape_html(blog.title)}</strong>, Content: #{CGI.escape_html(blog.content)}"
        response.write '</li>'
      end
      response.write '</ul>'
    end
  elsif request.get? && request.path == '/'
    response.write '<p><strong>Submit a new Blog Post!</p></strong>'
    response.write "<form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>"
    response.write "<p><label>Blog Title: <input name='title'></label></p>"
    response.write "<p><label>Content: <textarea name='content'></textarea></label></p>"
    response.write '<p><button>Submit post</button></p>'
    response.write '</form>'

    # Prepare response
    response.content_type = 'text/html'
    response.finish
  elsif request.get?
    response.write "method is #{request.request_method}, path is #{request.path}"
    response.content_type = 'text/plain'
    response.finish
  elsif request.post? && request.path == '/create-post'
    puts 'Got a new POST request!'

    blog = Blog.new(request.params)

    # Write to database
    database.execute('INSERT INTO blogs (title, content) VALUES (:title, :content)', blog.to_h)

    # Prepare response
    response.redirect('/show-data', 303)
    response.finish
  end
}

# Run the Puma app server with our web application
Rack::Handler::Puma.run(app, Port: 1234, Verbose: true)
