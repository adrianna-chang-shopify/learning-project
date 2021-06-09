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
    # Since we're accessing the URL helpers right on the module, we need to specify
    # both the host and port so that the full (absolute) URL can be constructed properly
    redirect_to MyApp.url_helpers.blogs_url(host: request.host, port: request.port), status: :see_other
  end
end

class PagesController < ActionController::Base
  def not_found
    @request_path = request.path_info
    render status: :not_found
  end
end

# Top level entry point to Rack application is the RouteSet!
MyApp = ActionDispatch::Routing::RouteSet.new
# Can mix the module with URL helpers right into the controller,
# or access them as singleton methods on the module returned by
# RouteSet#url_helpers
# BlogsController.include(MyApp.url_helpers)
MyApp.draw do
  resources :blogs
  match '*path', via: :all, to: 'pages#not_found'
end
