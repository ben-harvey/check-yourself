# parsed = {
#     "Song"=>
#           {
#             "Tempo"=>105,
#              "Flow"=>
#                   [
#                   {"Verse"=>"x4"}
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
#   }

parsed = {"Song"=>
  {"Tempo"=>100,
   "Flow"=>[{"Verse"=>"x2"}],
   "Kit"=>[{"bass"=>"house_2_1.wav"}, {"snare"=>"roland_tr_909_2.wav"}, {"hihat"=>"house_2_5.wav"}, {"cowbell"=>"big_beat_5.wav"}, {"deep"=>"house_2_2.wav"}]},
 "Verse"=>
  [{"bass"=>"................"}, {"snare"=>"................"}, {"hihat"=>"................"}, {"cowbell"=>"................"},  {"deep"=>"................"}],
"Chorus"=>
  [{"bass"=>"..XX`............."}, {"snare"=>"................"}, {"hihat"=>"................"}, {"cowbell"=>"................"},  {"deep"=>"................"}]}


parsed_new_kit = [
  {
    "bongo1"=> "bongo_1.wav"
  },
  {
    "bongo2"=> "bongo_2.wav"
  },
  {
    "bongo3"=> "bongo_3.wav"
  },
  {
    "bongo4"=> "bongo_4.wav"
  },
  {
    "bongo5"=> "bongo_5.wav"
  }
]

parsed_old_kit = [{"bass"=>"house_2_1.wav"}, {"snare"=>"roland_tr_909_2.wav"}, {"hihat"=>"house_2_5.wav"}, {"cowbell"=>"big_beat_5.wav"}, {"deep"=>"house_2_2.wav"}]
# get an array of key names from Kit
# for each pattern
  # map the kit names onto the instrument names


def get_kit_names(parsed_kit)
  parsed_kit.map do |hsh|
    hsh.keys.first
  end
end

old_kit_names = get_kit_names(parsed_old_kit) # ["bass", "snare", "hihat", "cowbell", "deep"]
new_kit_names = get_kit_names(parsed_new_kit)

patterns = parsed.reject { |k, v| k == "Song"}


patterns.each do |pattern|
  # cloned_kit = kit_names.clone
  pattern[1].each_with_index do |instrument, index|
    old_name = old_kit_names[index]
    new_name = new_kit_names[index]
    instrument[new_name] = instrument.delete(old_name)
  end
end
p patterns
=begin
=end

