require 'sinatra/base'
require 'pivotal_tracker'
require 'active_support/all'
require 'rack/ssl-enforcer'
require 'rdiscount'

PivotalTracker::Client.use_ssl = true

class CardOMatic < Sinatra::Base
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET'] || '1897bd5986da9'

  configure :production do
    use Rack::SslEnforcer
  end

  configure :development do
    require 'better_errors'
    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__
  end

  get '/' do
    @intro = true

    erb :start
  end

  post '/projects' do
    setup_api_key

    begin
      @projects = PivotalTracker::Project.all
    rescue RestClient::Unauthorized
      render_previous_step_with_error(:start, "We couldn't connect with your API key.")
    end

    erb :projects
  end

  post '/iterations' do
    setup_api_key
    setup_project

    @iterations = fetch_iterations(@project)

    erb :iterations
  end

  get '/render' do
    setup_api_key
    setup_project

    if params[:iteration].nil? || params[:iteration].empty?
      @iterations = fetch_iterations(@project)
      render_previous_step_with_error(:iterations, 'Please choose an iteration.')
    end

    @stories = case params[:iteration]
    when 'icebox'
      @project.stories.all(state: "unscheduled")
    when 'backlog'
      PivotalTracker::Iteration.backlog(@project).first.stories
    when /\d+/
      @project.iterations.all(offset: params[:iteration].to_i-1, limit: 1).first.stories
    when 'label'
      @project.stories.all(label: params[:label])
    end

    @stories.reject!{ |s| s.story_type == 'release'} # never print release-cards
    @stories.reject!{ |s| s.current_state == 'accepted'} # never print accepted-cards

    if params[:layout] == 'table'
      erb :stories_as_table, layout: false
    else
      erb :stories_as_cards, layout: false
    end
  end

  post '/render_stories' do
    setup_api_key
    setup_project
    story_ids = params[:story_ids].split(',')
    @stories = []

    story_ids.each do |id|
      @stories << @project.stories.find(id)
    end
    @stories.compact!

    erb :stories_as_cards, layout: false
  end

  def setup_project
    project_id = (params[:project_id] || session[:project_id]).to_i
    begin
      @project = PivotalTracker::Project.find(project_id)
      raise InvalidProjectId unless @project
    rescue RestClient::ResourceNotFound
      raise InvalidProjectId
    end
    session[:project_id] = project_id
  rescue InvalidProjectId
    @projects = PivotalTracker::Project.all
    render_previous_step_with_error(:projects, 'Please choose a project to print cards for.')
  end

  def setup_api_key
    @api_key = params[:api_key] || session[:api_key]

    if @api_key.nil? || @api_key.empty?
      render_previous_step_with_error(:start, 'Please enter an API key')
    end

    PivotalTracker::Client.token = @api_key
    session[:api_key] = @api_key
  end

  def fetch_iterations(project)
    start = project.current_iteration_number < 5 ? 1 : project.current_iteration_number-4
    stop  = project.current_iteration_number + 4
    (start..stop)
  end

  def render_previous_step_with_error(view, error)
    @error = error
    halt(400, erb(view))
  end

  class InvalidProjectId < StandardError; end
end
