=begin

Features
  -have preset kits

  -build custom kit

  - clear rhythm 

To do
  refactor change methods to delete session values after lookup
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

end

## view helpers ##

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
    find_pattern(pattern, @parsed_yaml)[pattern].chars.join(' ')
  end

  def each_instrument(instrument_array)
    instrument_array.each do |instrument_hash|
      instrument_hash.each do |instrument, rhythm|
        yield(instrument, rhythm)
      end
    end
  end
end

## validation helpers ##

def empty_input?(input)
  input.strip.empty?
end

def validate_name(name)
  'A name is required' if empty_input?(name)
end

## beat helpers ##

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

def change_rhythm(yaml_name)
  parsed = YAML.load(File.open(yaml_name))
  instrument = session.delete(:instrument)
  new_rhythm = session.delete(:rhythm)
  pattern = session.delete(:pattern)

  new_instrument_rhythm(instrument, pattern, parsed, new_rhythm)

  File.open(yaml_name, 'w') { |f| f.write(parsed.to_yaml) }
end

def change_pattern(yaml_name)
  parsed = YAML.load(File.open(yaml_name))
  pattern = session.delete(:pattern)
  repeats = session.delete(:repeats)

  find_pattern(pattern, parsed)[pattern] = "x#{repeats}"

  File.open(yaml_name, 'w') { |f| f.write(parsed.to_yaml) }
end

def add_pattern(yaml_name)
  parsed = YAML.load(File.open(yaml_name))
  pattern_title = session.delete(:pattern_title)
  new_pattern = session.delete(:new_pattern)

  parsed[pattern_title] = new_pattern
  parsed["Song"]["Flow"] << {pattern_title => "x2"}


  File.open(yaml_name, 'w') { |f| f.write(parsed.to_yaml) }
end

def change_tempo(yaml_name)
  parsed = YAML.load(File.open(yaml_name))
  new_tempo = session.delete(:tempo).to_i 

  parsed["Song"]["Tempo"] = new_tempo

  File.open(yaml_name, 'w') { |f| f.write(parsed.to_yaml) }
end

## file helpers ##

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

## routes ##

get '/' do
  @wav_name = replace_wav_file
  yaml_name = session[:yaml_name] || @blank_yaml_path

  change_tempo(yaml_name) if session[:tempo]
  add_pattern(yaml_name) if session[:new_pattern]
  change_rhythm(yaml_name) if session[:rhythm]
  change_pattern(yaml_name) if session[:repeats]
  render_beats(yaml_name, @wav_name)

  new_yaml_name = replace_yaml_file(yaml_name)
  @parsed_yaml = YAML.load(File.open(new_yaml_name))  # for helpers
  @tempo = get_tempo(@parsed_yaml)

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

#
#   {
#     "Song"=>
#           {
#             "Tempo"=>105,
#              "Flow"=>
#                   [
#                   {"Verse"=>"x4"}, {"Chorus"=>"x4"}
#                   ],
#              "Kit"=>
#              [
#               {"bass"=>"sounds/house_2_1.wav"},
#               {"snare"=>"sounds/roland_tr_909_2.wav"},
#               {"hihat"=>"sounds/house_2_5.wav"},
#               {"cowbell"=>"sounds/big_beat_5.wav"},
#                {"deep"=>"sounds/house_2_2.wav"}
#               ]
#           },
#     "Verse"=>
#           [
#             {"bass"=>"X..X...X..X..XX"},
#             {"snare"=>"....X.......X..."},
#             {"hihat"=>"..X...X...X...X."}
#           ],
#     "Chorus"=>
#           [
#             {"bass"=>"X..X...X..X....."},
#             {"snare"=>"....X.......X..."},
#             {"hihat"=>"XXXXXXXXXXXXX..."},
#             {"cowbell"=>"....XX.X..X.X..."},
#             {"deep"=>".............XX."}
#           ]
#   }
#