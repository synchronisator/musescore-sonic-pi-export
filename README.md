# musescore-sonic-pi-export
A Musescore 3.x Plugin to export a score to Sonic Pi Code

# Features

- Export complete score into sonic pi code
- The code has a "fromMeasure" / "untilMeasure" Option to only play parts of the score in a loop
- optional Metronome
- optional midi output
- tracks can be disabled by flag (0 or 1 instead of false/true because its faster to edit :) 

# Limitations
- No support for repeatings. Use "Tools > Unroll Repeats"
- No support for changing BPM within the score

# Todos
- Metronome before Starting melody
- Different Outputs
- Different Midi channels
- Tie/Slur-Support
- Create UI
    - choose outputfile
