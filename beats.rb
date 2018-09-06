=begin

Features
  -have preset kits
    on first load, current kit is default.  store current kit in variable.
    kits list shouldn't include current kit

  - clear rhythm

=end
require 'yaml'
require 'psych'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'pry'
require 'fileutils'
require 'tempfile'
require 'securerandom'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  @blank_yaml_path = "yaml/blank.yaml"
  @blank_pattern_path = "yaml/blank_pattern.yaml"
  @kits_path = File.join(app_path, "yaml", "kits")
  session[:kit] ||= "default"
end

##### view helpers #####

helpers do
  def each_pattern
    patterns = @parsed_yaml.reject { |k, v| k == "Song"}
    patterns.each do |pattern, instrument_array|
      yield(pattern, instrument_array)
    end
  end

  # returns a string or nil
  def checked_box(note)
    "checked" if note == "X"
  end

  def repeats(pattern)
    find_pattern(pattern, @parsed_yaml)[pattern].chars.last
  end

  def each_instrument(instrument_array)
    instrument_array.each do |instrument_hash|
      instrument_hash.each do |instrument, rhythm|
        yield(instrument, rhythm)
      end
    end
  end

  # returns a string or nil
  def selected_kit(kit)
    "selected" if session[:kit] == kit
  end

  def selected_repeats(number, pattern)
    repeats = find_pattern(pattern, @parsed_yaml)[pattern].chars.last
    "selected" if number.to_s == repeats
  end

  def each_kit
    Dir[@kits_path + "/*"].each do |kit|
      yield File.basename(kit, ".yaml")
    end
  end
end

##### validation helpers #####

def empty_input?(input)
  input.strip.empty?
end

def validate_name(name)
  'A name is required' if empty_input?(name)
end

##### beat helpers #####

def render_beats(yaml_file, wav_file)
  session[:message] = `beats --path sounds #{yaml_file} public/#{wav_file}`
end

def get_tempo(parsed_yaml)
  parsed_yaml["Song"]["Tempo"]
end

# returns a hash of {"$pattern"=> "x$repeats"}
def find_pattern(pattern, parsed_yaml)
    parsed_yaml["Song"]["Flow"].find {|patterns| patterns.has_key?(pattern)}
end

def new_instrument_rhythm(instrument, pattern, parsed_yaml, new_rhythm)
  pattern = parsed_yaml[pattern]
  rhythm = pattern.find { |rhythms|  rhythms.has_key?(instrument) }
  if rhythm
    rhythm[instrument] = new_rhythm
  else
    pattern << {instrument => new_rhythm}
  end
end

##### beat changers #####

# consider adding return value directly to parsed_yaml in route to avoid
# opening and writing to file in each method

def change_rhythm(parsed_yaml, yaml_name)
  instrument = session.delete(:instrument)
  new_rhythm = session.delete(:rhythm)
  pattern = session.delete(:pattern)

  new_instrument_rhythm(instrument, pattern, parsed_yaml, new_rhythm)

  write_to_yaml(parsed_yaml, yaml_name)
end

def change_pattern(parsed_yaml, yaml_name)
  pattern = session.delete(:pattern)
  repeats = session.delete(:repeats)

  find_pattern(pattern, parsed_yaml)[pattern] = "x#{repeats}"

  write_to_yaml(parsed_yaml, yaml_name)
end



# def change_kit(parsed_yaml, yaml_name)
#   pattern = session.delete(:pattern)
#   kit = session[:kit]  # this is the kit name
#
    # kit_path = path to kit + kit name + .yaml



#   parsed_yaml["Song"]["Kit"] = new_kit

#   write_to_yaml(parsed_yaml, yaml_name)
# end

def add_pattern(parsed_yaml, yaml_name)
  pattern_title = session.delete(:pattern_title)
  new_pattern = session.delete(:new_pattern)

  parsed_yaml[pattern_title] = new_pattern
  parsed_yaml["Song"]["Flow"] << {pattern_title => "x2"}


  write_to_yaml(parsed_yaml, yaml_name)
end

def change_tempo(parsed_yaml, yaml_name)
  new_tempo = session.delete(:tempo).to_i

  parsed_yaml["Song"]["Tempo"] = new_tempo

  write_to_yaml(parsed_yaml, yaml_name)
end

##### file helpers #####

# consider refactoring
def replace_wav_file
  if session[:last_wav_name]
    path = File.join("public", session[:last_wav_name])
    FileUtils.rm(path)
  end
  session[:last_wav_name] = "#{random_filename}.wav"
end

# consider refactoring
def replace_yaml_file(old_yaml_name)
  new_yaml_name = "yaml/#{random_filename}.yaml"
  FileUtils.cp(old_yaml_name, new_yaml_name)
  FileUtils.rm(old_yaml_name) unless old_yaml_name == @blank_yaml_path

  session[:yaml_name] = new_yaml_name
end

def random_filename
  SecureRandom.uuid
end

def write_to_yaml(parsed_yaml, yaml_name)
  File.open(yaml_name, 'w') { |f| f.write(parsed_yaml.to_yaml) }
end

def app_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test', __FILE__)
  else
    File.expand_path('..', __FILE__)
  end
end

##### routes #####

get '/' do
  @wav_name = replace_wav_file
  yaml_name = session[:yaml_name] || @blank_yaml_path
  parsed_yaml = YAML.load(File.open(yaml_name))

  change_tempo(parsed_yaml, yaml_name) if session[:tempo]
  add_pattern(parsed_yaml, yaml_name) if session[:new_pattern]
  change_rhythm(parsed_yaml, yaml_name) if session[:rhythm]
  change_pattern(parsed_yaml, yaml_name) if session[:repeats]


  render_beats(yaml_name, @wav_name)

  new_yaml_name = replace_yaml_file(yaml_name)
  @parsed_yaml = YAML.load(File.open(new_yaml_name))  # for helpers
  @tempo = get_tempo(@parsed_yaml)
  @kit = session[:kit]

  erb :play
end

get '/song/new_pattern' do
  erb :add
end

post '/song/update/tempo' do
  session[:tempo] = params[:tempo]

  redirect '/'
end

post '/rhythm/:pattern/:instrument' do
  session[:instrument] = params[:instrument]
  session[:pattern] = params[:pattern]

  rhythm = ['.'] * 16
  params[:rhythm] ||= []
  notes = params[:rhythm].map(&:to_i)
  notes.each { |note| rhythm[note] = 'X' }
  session[:rhythm] = rhythm.join


  redirect "/"
end

post '/song/new_pattern' do
  @pattern_title = params[:title]

  if validate_name(@pattern_title)
    session[:message] = validate_name(@pattern_title)
    status 422

   erb :add
  else
    session[:new_pattern] = YAML.load(File.open(@blank_pattern_path))
    session[:pattern_title] = @pattern_title
    redirect '/'
  end
end

post "/song/update/:pattern" do
  session[:pattern] = params[:pattern]
  session[:repeats] = params[:repeats]

  redirect "/"
end

post "/song/change-kit" do
  session[:kit] = params[:kit]

  redirect "/"
end
