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

class BlogsController < ActionController::Base
  def new
  end

  def index
    @blogs = Blog.all
  end

  def create
    puts 'Got a new POST request!'
    Blog.create!(params.permit(:title, :content))
    redirect_to "/blogs", status: :see_other
  end
end

class PagesController < ActionController::Base
  def not_found
    @request_path = request.path_info
    render status: :not_found
  end
end

class MyApp
  def initialize
    @router = ActionDispatch::Routing::RouteSet.new
    @router.draw do
      resources :blogs
      match '*path', via: :all, to: 'pages#not_found'
    end
  end

  def call(environment)
    @router.call(environment)
  end
end
