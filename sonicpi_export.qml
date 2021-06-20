import QtQuick 2.0
import MuseScore 3.0
import FileIO 3.0

MuseScore {
    menuPath: "Plugins.SonicPiExporter"
    description: "Exports the selected Score to a nameOfScore.rb in your Homedirectory"
    requiresScore: true;
    version: "1.0"


    FileIO {
        id: sonicFile
        source: homePath()
        onError: console.log(msg + "  Filename = " + sonicFile.source)
    }

    onRun: {
        if (typeof curScore === 'undefined')
            Qt.quit();

        //TODO disable tracks by bool in SonicPi
        //TODO disable metrum by bool in SonicPi
        //TODO detect numerator / denominator
        //TODO Tie/Slur-Support
        //TODO create better beat
        //TODO name tracks correct

        //UI
        // - midi or not
        // - metronome or not
        // - choose outputfile

        var isMidi = 1; //TODO UI
        var hasMetronome = 1; //TODO UI
        var scoreName = curScore.scoreName
        var outputFile = sonicFile.source + "/" + scoreName + ".rb" //TODO UI


        var cursor = curScore.newCursor()
        cursor.rewind(0)
        var maximumDuration = curScore.lastSegment.tick

        var mapPitches = new Map();
        var mapRests = new Map();

        for (var staff=0; staff<curScore.nstaves; staff++) {
            for (var i=0; i<4; i++) {
                var hasContent = false;
                mapPitches.set(staff + "_" +  i, "");
                mapRests.set(staff + "_" +  i, "");
                var currentStaff = (staff*4) +i;
                var cursor = curScore.newCursor()
                cursor.rewind(0)
                cursor.track = currentStaff
                var lastTick = 0
                var s = "";
                var r = "";
                while (cursor.segment) {
                    if(lastTick !== cursor.tick){
                        var duration = (cursor.tick - lastTick)/480
                        s += "nil,";
                        r += duration + ","
                        lastTick = cursor.tick
                    }
                    var element = cursor.segment.elementAt(currentStaff);
                    if(element !== null){
                        if (element.type === Element.CHORD) {
                            var duration = ((element.globalDuration.numerator /element.globalDuration.denominator)*4.0)
                            lastTick += (duration*480)
                            for (var j=0; j<element.notes.length; j++) {
                                hasContent = true;
                                s += element.notes[j].pitch + ",";
                                if(j == element.notes.length-1){
                                    r += duration + ",";
                                } else {
                                    r += "0,";
                                }
                            }
                        } else if (element.type ===  Element.REST){
                            var duration = ((element.globalDuration.numerator /element.globalDuration.denominator)*4.0)
                            lastTick += (duration*480)
                            s += "nil,";
                            r += duration + ","
                        }
                    }
                    cursor.next()
                }
                if(lastTick !== 0 && lastTick !== maximumDuration){
                    var duration = (maximumDuration - lastTick)/480
                    s += "nil,";
                    r += duration + ","
                    lastTick = cursor.tick
                }
                if(hasContent){
                    var st = staff + "_" +  i;
                    mapPitches.set(st, mapPitches.get(st) + s);
                    mapRests.set(st, mapRests.get(st) + r);
                }
            }
        }

        var returnString = "\r\n #### Sonic Pi Code #### \r\n";
        var tempo = 1
        var cs = curScore.newCursor();
        cs.rewind(0)
        for (var i = cs.segment.annotations.length; i-- > 0; ) {
            if (cs.segment.annotations[i].type === Element.TEMPO_TEXT) {
                tempo = cs.segment.annotations[i].tempo
            }
        }

        returnString += "use_bpm " + (tempo*60) + " \r\n";
        returnString += " \r\n";
        returnString += "fromMeasure = nil    # nil or Number \r\n";
        returnString += "untilMeasure = nil   # nil or Number \r\n";
        returnString += " \r\n";
        returnString += "numerator = 6.0 \r\n"; //TODO
        returnString += "denominator = 8.0 \r\n"; //TODO
        returnString += "quarterPerMeasure = numerator/(denominator/4.0) \r\n";
        returnString += " \r\n";

        if(hasMetronome){
            returnString += "simpleMetronomeBeat = ' 966 '  # Number for 0.1 amp or - for nothing \r\n"; //TODO
            returnString += "simpleMetronomeBeatSleep = 0.5 \r\n"; //TODO
            returnString += "simpleMetronomeAmpMultiplier = 5 \r\n";
        }

        returnString += " \r\n";
        returnString += "use_midi_defaults channel: 1, port: 'Midi Through Port-0' \r\n";
        returnString += "midi_pc 12, channel: 1 \r\n";
        returnString += " \r\n";
        returnString += "define :play_timed do |channel, notes, times, **args| \r\n";
        returnString += "ts = times.ring \r\n";
        returnString += "measure = 0 \r\n";
        returnString += "index = 0 \r\n";
        returnString += "if fromMeasure != nil \r\n";
        returnString += "fm = (fromMeasure-1) * quarterPerMeasure \r\n";
        returnString += "while measure < fm      #goto fromMeasure \r\n";
        returnString += "measure += ts[index] \r\n";
        returnString += "index += 1 \r\n";
        returnString += "end \r\n";
        returnString += "if measure != fm      #   make a correction of 'starting inside a rest' \r\n";
        returnString += "sleep measure - fm \r\n";
        returnString += "end \r\n";
        returnString += "end \r\n";
        returnString += "if untilMeasure != nil \r\n";
        returnString += "um = (untilMeasure) * quarterPerMeasure \r\n";
        returnString += "end \r\n";
        returnString += "measure = 0 #reset \r\n";
        returnString += "notes.each_with_index do |note, i| \r\n";
        returnString += "measure += ts[i] \r\n";
        returnString += "if i < index \r\n";
        returnString += "next \r\n";
        returnString += "end \r\n";
        if(isMidi){
            returnString += "midi";
        } else {
            returnString += "play";
        }
        returnString += " note, sustain: ts[i], channel: channel \r\n";
        returnString += "sleep ts[i] \r\n";
        returnString += "if untilMeasure != nil && measure >= um \r\n";
        returnString += "break \r\n";
        returnString += "end \r\n";
        returnString += "end \r\n";
        returnString += "end \r\n";
        returnString += " \r\n";

        if(hasMetronome){
            returnString += "def pat(p) \r\n";
            returnString += "p.delete(' ').split('').map{ |v|  v.to_f / 10  }.ring \r\n";
            returnString += "end \r\n";
            returnString += " \r\n";
            returnString += "live_loop :metronome do \r\n"
            returnString += "tick('metronome') \r\n"
            returnString += "if (pat(simpleMetronomeBeat).look('metronome')) > 0.0 \r\n"
            returnString += "sample :perc_snap,        amp: (pat(simpleMetronomeBeat).look('metronome')) * simpleMetronomeAmpMultiplier \r\n"
            returnString += "end \r\n"
            returnString += "sleep simpleMetronomeBeatSleep \r\n"
            returnString += "end \r\n"
            returnString += " \r\n";
        }

        for (var key of mapPitches.keys()) {
            if(mapPitches.get(key)  !== ""){
                returnString += ("live_loop :loop_" + key + " do\r\n");
                returnString += "pitches = [" + mapPitches.get(key) + "] \r\n";
                returnString += "rests = [" + mapRests.get(key) + "] \r\n";
                if(isMidi){
                    returnString += "play_timed 1,"
                }else{
                    returnString += "play_timed"
                }
                returnString += ( " pitches,rests \r\n" );
                returnString += ("end #" + key + "\r\n");
            }
        }
        sonicFile.source = outputFile
        console.log(sonicFile.source)
        console.log("Successfull? " + sonicFile.write(returnString))
        Qt.quit()
   }
}
