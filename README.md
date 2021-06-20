# musescore-sonic-pi-export
A Musescore 3.x Plugin to export a score to Sonic Pi Code

# Features

- Export complete score into sonic pi code
- The code has a "fromMeasure" / "untilMeasure" Option to only play parts of the score in a loop
- optional Metronome
- optional midi output

# Limitations
- No Support for repeatings. Use "Tools > Unroll Repeats"

# Todos
- disable tracks by bool in SonicPi
- disable metrum by bool in SonicPi
- detect numerator / denominator
- Remove Staff with no content
- Tie/Slur-Support
- create better beat
- name tracks correct
  
- Create UI
    - midi or not
    - metronome or not
    - choose outputfile
