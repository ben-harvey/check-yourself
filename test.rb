parsed = {
    "Song"=>
          {
            "Tempo"=>105,
             "Flow"=>
                  [
                  {"Verse"=>"x4"}, {"Chorus"=>"x4"}
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
    "Chorus"=>
          [
            {"bass"=>"X..X...X..X....."},
            {"snare"=>"....X.......X..."},
            {"hihat"=>"XXXXXXXXXXXXX..."},
            {"cowbell"=>"....XX.X..X.X..."},
            {"deep"=>".............XX."}
          ]
  }


p parsed["Song"]["Flow"].find

=begin
=end
