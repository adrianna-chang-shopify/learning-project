### Require dependencies
require 'action_controller'
require 'action_dispatch'
require 'active_record'
require 'cgi'

class Blog < ActiveRecord::Base; end

ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: "application.sqlite3"
)

# Create the table if it doesn't exist, seed some data
ActiveRecord::Schema.define do
  unless table_exists?(:blogs)
    create_table :blogs do |t|
      t.string :title
      t.text :content
    end
    Blog.create!(title: 'My awesome blog!', content: 'my favourite HTML tags are <p> and <script>')
    Blog.create!(title: 'Another cool blog!', content: 'my favourite HTML tags are <br> and <hr>')
  end
end

class AppController < ActionController::Base
  def root
    erb_response = <<~ERB
      <p><strong>Submit a new Blog Post!</p></strong>
      <form method='post' enctype='application/x-www-form-urlencoded' action='/create-post'>
      <label>Blog Title: <input name='title'></label></p>
      <p><label>Content: <textarea name='content'></textarea></label></p>
      <p><button>Submit post</button></p>
      </form>
    ERB
    render inline: erb_response
  end

  def show_data
    @blogs = Blog.all

    erb_response = <<~ERB
      <ul>
      <% @blogs.each do |blog| %>
        <li>
          <strong>Title: <%= CGI.escape_html(blog.title) %> </strong>, Content: <%= CGI.escape_html(blog.content) %>
        </li>
      <% end %>
      </ul>
    ERB
    render inline: erb_response
  end

  def create_post
    puts 'Got a new POST request!'

    # Blog.create!(title: params[:title], content: params[:content])
    Blog.create!(params.permit(:title, :content))
    redirect_to "/show-data", status: :see_other
  end

  def not_found
    @request_path = request.path_info

    erb_response = <<~ERB
      Sorry, I don’t know what <%= @request_path %> is 😢
    ERB
    render inline: erb_response, status: :not_found
  end
end

class MyApp
  def initialize
    @router = ActionDispatch::Routing::RouteSet.new
    draw_routes
  end

  def call(environment)
    @router.call(environment)
  end

  private

  def draw_routes
    @router.draw do
      root to: AppController.action(:root)
      get '/show-data', to: AppController.action(:show_data)
      post 'create-post', to: AppController.action(:create_post)
      match '*path', via: :all, to: AppController.action(:not_found)
    end
  end
end
