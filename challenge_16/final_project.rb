### Require dependencies
require 'action_controller'
require 'action_dispatch'
require 'active_record'

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

# Global configuration for view paths
ActionController::Base.append_view_path('views')

class AppController < ActionController::Base
  # We could actually omit this, and ActionController would still render our template :)
  def root
  end

  def show_data
    @blogs = Blog.all
  end

  def create_post
    puts 'Got a new POST request!'
    Blog.create!(params.permit(:title, :content))
    redirect_to "/show-data", status: :see_other
  end

  def not_found
    @request_path = request.path_info
    render status: :not_found
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
