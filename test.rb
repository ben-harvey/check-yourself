parsed = {
    "Song"=>
          {
            "Tempo"=>105,
             "Flow"=>
                  [
                  {"Verse"=>"x4"}
                  ],
             "Kit"=>
             [
              {"bass"=>"sounds/house_2_1.wav"},
              {"snare"=>"sounds/roland_tr_909_2.wav"},
              {"hihat"=>"sounds/house_2_5.wav"},
              {"cowbell"=>"sounds/big_beat_5.wav"},
               {"deep"=>"sounds/house_2_2.wav"}
              ]
          },
    "Verse"=>
          [
            {"bass"=>"X..X...X..X..XX"},
            {"snare"=>"....X.......X..."},
            {"hihat"=>"..X...X...X...X."}
          ],
  }

# Song::Flow::Pattern::Track::Rhythm

new_pattern =
          [
            {"bass"=>"X..X...X..X....."},
            {"snare"=>"....X.......X..."},
            {"hihat"=>"XXXXXXXXXXXXX..."},
            {"cowbell"=>"....XX.X..X.X..."},
            {"deep"=>".............XX."}
          ]

name = "Chorus"
p parsed
p "------------"
def add_pattern(name, parsed_yaml)
  parsed_yaml[name] = new_pattern
  parsed_yaml["Song"]["Flow"] << {name => "x2"}


p parsed
=begin
=end
