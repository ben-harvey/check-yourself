# rubocop:disable Metrics/BlockLength
require 'yaml'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'pry' if development?
require 'fileutils'
require 'securerandom'

configure do
  enable :sessions
  set :session_secret, 'superdupersecret'
end

before do
  @blank_yaml_path = 'yaml/blank.yaml'
  @kits_path = File.join(app_path, 'yaml', 'kits')
  @song_parts = %w(Verse Prechorus Chorus Bridge Outro)
  session[:kit] ||= 'default'
end

##### view helpers #####

helpers do
  def each_pattern
    patterns = @parsed_yaml.reject { |section, _| section == 'Song' }
    patterns.each do |pattern, instrument_array|
      yield(pattern, instrument_array)
    end
  end

  def checked_box?
    checked_box = false
    each_pattern do |pattern, _|
      checked_box = true if joined_rhythms(pattern).include?('X')
    end
    checked_box
  end

  def each_part
    each_pattern do |pattern, _|
      @song_parts.reject! { |part| part == pattern }
    end
    @song_parts.each do |part|
      yield part
    end
  end

  # returns a string or nil
  def checked_box(note)
    'checked' if note == 'X'
  end

  # returns a string or nil
  def selected_kit(kit)
    'selected' if session[:kit] == kit
  end

  def repeats(pattern)
    find_pattern(pattern, @parsed_yaml)[pattern].chars.last
  end

  def selected_repeats(number, pattern)
    repeats = find_pattern(pattern, @parsed_yaml)[pattern].chars.last
    'selected' if number.to_s == repeats
  end

  def each_kit
    Dir[@kits_path + '/*'].each do |kit|
      yield File.basename(kit, '.yaml')
    end
  end

  def joined_rhythms(pattern)
    @parsed_yaml[pattern].map { |hsh| hsh.values.first }.join
  end

  def instrument_name(instrument_array, index)
    index = (index / 16)
    instrument_array[index].keys.first
  end
end

##### file helpers #####

# replaces file and returns a string
def replace_yaml_file(old_yaml_name)
  new_yaml_name = "yaml/#{random_filename}.yaml"
  FileUtils.cp(old_yaml_name, new_yaml_name)

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

# returns yaml name and resets session
def set_yaml_name
  if session[:reset]
    session.delete(:reset)
    session[:kit] = 'default'
    @blank_yaml_path
  elsif session[:yaml_name]
    session[:yaml_name]
  else
    @blank_yaml_path
  end
end

##### beat helpers #####

def render_beats(yaml_file, wav_file)
  `beats --path sounds #{yaml_file} public/#{wav_file}`
end

def get_tempo(parsed_yaml)
  parsed_yaml['Song']['Tempo']
end

# returns a hash of {'$pattern'=> 'x$repeats'}
def find_pattern(pattern, parsed_yaml)
  parsed_yaml['Song']['Flow'].find { |patterns| patterns.key?(pattern) }
end

def swap_instruments(old_kit_instruments, new_kit_instruments, patterns)
  patterns.each do |pattern|
    pattern[1].each_with_index do |instrument, index|
      old_instrument = old_kit_instruments[index]
      new_instrument = new_kit_instruments[index]
      instrument[new_instrument] = instrument.delete(old_instrument)
    end
  end
end

def generate_new_pattern
  parsed_kit = parsed_kit(session[:kit])
  instruments(parsed_kit).map do |name|
    { name => '................' }
  end
end

def parsed_kit(kit)
  kit_path = File.join(@kits_path, (kit + '.yaml'))
  YAML.load(File.open(kit_path))
end

def instruments(parsed_kit)
  parsed_kit.map do |hsh|
    hsh.keys.first
  end
end

def each_rhythm_and_instrument(joined_rhythm, parsed_kit)
  rhythms = joined_rhythm.each_slice(16).map(&:join)
  instruments = instruments(parsed_kit)
  rhythms_and_instruments = rhythms.zip(instruments)
  rhythms_and_instruments.each do |rhythm, instrument|
    yield(rhythm, instrument)
  end
end

##### beat changers #####

def change_rhythm(parsed_yaml, yaml_name)
  joined_rhythm = session.delete(:rhythm)
  pattern = session.delete(:pattern)
  current_kit = session[:kit]
  parsed_kit = parsed_kit(current_kit)

  each_rhythm_and_instrument(joined_rhythm, parsed_kit) do |rhythm, instrument|
    new_instrument_rhythm(rhythm, instrument, pattern, parsed_yaml)
  end
  write_to_yaml(parsed_yaml, yaml_name)
end

def new_instrument_rhythm(new_rhythm, instrument, pattern, parsed_yaml)
  pattern = parsed_yaml[pattern]
  rhythm = pattern.find { |rhythms| rhythms.key?(instrument) }
  if rhythm
    rhythm[instrument] = new_rhythm
  else
    pattern << { instrument => new_rhythm }
  end
end

def change_pattern(parsed_yaml, yaml_name)
  pattern = session.delete(:pattern)
  repeats = session.delete(:repeats)

  find_pattern(pattern, parsed_yaml)[pattern] = "x#{repeats}"

  write_to_yaml(parsed_yaml, yaml_name)
end

# rubocop:disable Metrics/AbcSize
def change_kit(parsed_yaml, yaml_name)
  old_kit = session.delete(:old_kit)
  old_kit_instruments = instruments(parsed_kit(old_kit))

  new_kit = session[:kit]
  new_kit_instruments = instruments(parsed_kit(new_kit))

  patterns = parsed_yaml.reject { |section, _| section == 'Song' }
  parsed_yaml['Song']['Kit'] = parsed_kit(new_kit)
  swap_instruments(old_kit_instruments, new_kit_instruments, patterns)

  write_to_yaml(parsed_yaml, yaml_name)
end
# rubocop:enable Metrics/AbcSize

def add_pattern(parsed_yaml, yaml_name)
  pattern_title = session.delete(:pattern_title)
  new_pattern = generate_new_pattern

  parsed_yaml[pattern_title] = new_pattern
  parsed_yaml['Song']['Flow'] << { pattern_title => 'x2' }

  write_to_yaml(parsed_yaml, yaml_name)
end

def change_tempo(parsed_yaml, yaml_name)
  new_tempo = session.delete(:tempo).to_i

  parsed_yaml['Song']['Tempo'] = new_tempo

  write_to_yaml(parsed_yaml, yaml_name)
end

##### routes #####

# main app engine

get '/' do
  @wav_name = "#{random_filename}.wav"
  yaml_name = set_yaml_name

  parsed_yaml = YAML.load(File.open(yaml_name))

  change_tempo(parsed_yaml, yaml_name) if session[:tempo]
  add_pattern(parsed_yaml, yaml_name) if session[:pattern_title]
  change_rhythm(parsed_yaml, yaml_name) if session[:rhythm]
  change_pattern(parsed_yaml, yaml_name) if session[:repeats]
  change_kit(parsed_yaml, yaml_name) if session[:old_kit]

  render_beats(yaml_name, @wav_name)

  new_yaml_name = replace_yaml_file(yaml_name)
  @parsed_yaml = YAML.load(File.open(new_yaml_name))
  @tempo = get_tempo(@parsed_yaml)
  @kit = session[:kit]

  erb :play
end

post '/song/update-tempo' do
  session[:tempo] = params[:tempo]

  redirect '/'
end

post '/:pattern/update-rhythm' do
  session[:pattern] = params[:pattern]

  rhythm = ['.'] * 80
  params[:rhythm] ||= []
  notes = params[:rhythm].map(&:to_i)
  notes.each { |note| rhythm[note] = 'X' }
  session[:rhythm] = rhythm

  redirect '/'
end

post '/song/new-pattern' do
  session[:pattern_title] = params[:title]
  redirect '/'
end

post '/song/update/:pattern' do
  session[:pattern] = params[:pattern]
  session[:repeats] = params[:repeats]

  redirect '/'
end

post '/song/change-kit' do
  session[:old_kit] = session[:kit]
  session[:kit] = params[:kit]

  redirect '/'
end

post '/reset' do
  session[:reset] = true

  redirect '/'
end
