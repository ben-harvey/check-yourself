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


# def change_instrument_pattern(instrument, flow_section, parsed_yaml, new_pattern)
# pattern = parsed_yaml[flow_section].find {|patterns|  patterns.has_key?(instrument)}
# pattern[instrument] = new_pattern
# end

=begin
 Verse:
    bass
      checkboxes
    snare
      checkboxes
    hihat
      checkboxes
=end


def render_checkboxes(parsed)
  # parsed = YAML.load(File.open(yaml_file))
  flow_sections = parsed.reject { |k, v| k == "Song"}
  flow_sections.each do |flow_section, instrument_array|
    p flow_section
    p instrument_array
  #   instrument_array.each do |instrument_hash|
  #     instrument_hash.each do |instrument, pattern|
  #       yield({flow_section => [instrument, pattern]})
  #     end
  #   end
  end
end

render_checkboxes(parsed)