=begin

Features
  have preset kits
    later, have build kit feature

  set number of repeats

  add new flow section


To do



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
end


helpers do
  def each_flow_section
    flow_sections = @yaml_file.reject { |k, v| k == "Song"}
    flow_sections.each do |flow_section, instrument_array|
      yield(flow_section, instrument_array)
    end
  end

  # returns a string or nil
  def checked_box(note)
    "checked" if note == "X"
  end

  def repeats(flow_section)
    find_section(flow_section).chars.join(' ')
  end

  def each_instrument(instrument_array)
    instrument_array.each do |instrument_hash|
      instrument_hash.each do |instrument, pattern|
        yield(instrument, pattern)
      end
    end
  end
end

## beat helpers ##

def render_beats(yaml_file, wav_file)
  session[:message] = `beats --path sounds #{yaml_file} public/#{wav_file}`
end

def change_tempo(parsed_yaml, new_tempo)
  parsed_yaml["Song"]["Tempo"] = new_tempo
end

 def find_section(flow_section)
    section = @yaml_file["Song"]["Flow"].find {|sections| sections.has_key?(flow_section)}
    section[flow_section]
  end

def new_instrument_pattern(instrument, flow_section, parsed_yaml, new_pattern)
  section = parsed_yaml[flow_section]
  pattern = section.find { |patterns|  patterns.has_key?(instrument) }
  if pattern
    pattern[instrument] = new_pattern
  else
    section << {instrument => new_pattern}
  end
end

def change_pattern(yaml_name, instrument)
  parsed = YAML.load(File.open(yaml_name))

  new_pattern = session[:pattern]
  new_instrument_pattern(instrument, "Verse", parsed, new_pattern)

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

  change_pattern(yaml_name, session[:instrument]) if session[:pattern]
  render_beats(yaml_name, @wav_name)

  new_yaml_name = replace_yaml_file(yaml_name)
  @yaml_file = YAML.load(File.open(new_yaml_name))  # for helpers

  erb :play
end


post '/pattern/:instrument' do
  session[:instrument] = params[:instrument]

  pattern = ['.'] * 16
  params[:pattern] ||= []
  notes = params[:pattern].map(&:to_i)
  notes.each { |note| pattern[note] = 'X' }
  session[:pattern] = pattern.join


  redirect "/"
end

post "/section/:flow_section" do
  flow_section = params[:flow_section]
  def find_section(flow_section)
    section = @yaml_file["Song"]["Flow"].find {|sections| sections.has_key?(flow_section)}
    section[flow_section]
  end
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