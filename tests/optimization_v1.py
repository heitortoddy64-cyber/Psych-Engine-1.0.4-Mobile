#!/usr/bin/env python3
"""Exercise the changed Haxe statements with small stand-ins, not the full engine.

Run from the repository root: python3 tests/optimization_v1.py
Requires Haxe 4.3.7 on PATH. No HaxeFlixel/Android libraries are required.
"""

import argparse
from pathlib import Path
import re
import subprocess
import tempfile


def block(source, marker):
    start = source.index(marker)
    opening = source.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


TEMPLATE = r'''
class StrumNote {
    public var sustainReduce = true;
    public function new() {}
}
class FlxTypedGroup<T> {
    public var members:Array<T> = [];
    public var length(get, never):Int;
    function get_length() return members.length;
    public function new() {}
    public function insert(i:Int, item:T) members.insert(i, item);
}
class Note {
    public var id:String;
    public var strumTime:Float = 0;
    public var multSpeed:Float = 1;
    public var noteData = 0;
    public var noteType = "Custom Note";
    public var isSustainNote = false;
    public var spawned = false;
    public var exists = true;
    public var active = true;
    public var visible = true;
    public var mustPress = true;
    public var blockHit = false;
    public var canBeHit = true;
    public var wasGoodHit = false;
    public var hitByOpponent = false;
    public var ignoreNote = false;
    public var tooLate = false;
    public var visits = 0;
    public var clips = 0;
    public function new(id:String) this.id = id;
    public function followStrumNote(s:StrumNote, crochet:Float, speed:Float) {
        if (++visits > 100) throw "loop failed to advance past " + id;
        Fixture.check(s != null && crochet == 500 && speed == 1, "note positioning arguments");
    }
    public function clipToStrumNote(s:StrumNote) clips++;
}
class Conductor { public static var songPosition:Float = 0; }
class Watch {
    public var entries:Array<String> = [];
    public function new() {}
    public function addQuick(name:String, value:Int) entries.push(name + ":" + value);
}
class FlxG {
    public static var save:{data:Dynamic} = {data: {}};
    public static var drawFramerate = 90;
    public static var updateFramerate = 90;
    public static var autoPause = false;
    public static var watch = new Watch();
}
class Main { public static var fpsVar = {visible: true}; }
class ClientPrefs { public static var data:Dynamic; }
class Fixture {
    static var assertions = 0;
    public static function check(ok:Bool, message:String) {
        if (!ok) throw message;
        assertions++;
    }
    var notes = new FlxTypedGroup<Note>();
    var unspawnNotes:Array<Note> = [];
    var playerStrums = new FlxTypedGroup<StrumNote>();
    var opponentStrums = new FlxTypedGroup<StrumNote>();
    var spawnTime:Float = 10;
    var playbackRate:Float = 1;
    var songSpeed:Float = 1;
    var SONG = {bpm: 120.0};
    var noteKillOffset:Float = 350;
    var cpuControlled = false;
    var endingSong = false;
    var misses = 0;
    var events:Array<String> = [];
    var luaAction:Note->Void = function(_) {};
    var hscriptAction:Note->Void = function(_) {};
    var curSection = 2;
    var curBeat = 8;
    var curStep = 32;
    function new() {
        playerStrums.members.push(new StrumNote());
        opponentStrums.members.push(new StrumNote());
    }
    function callOnLuas(event:String, args:Array<Dynamic>) {
        var note = notes.members[args[0]];
        check(event == "onSpawnNote" && note.spawned, "Lua spawn event and state");
        check(args.length == 5 && args[1] == note.noteData && args[2] == note.noteType
            && args[3] == note.isSustainNote && args[4] == note.strumTime, "Lua spawn arguments");
        events.push("lua:" + note.id);
        luaAction(note);
    }
    function callOnHScript(event:String, args:Array<Note>) {
        check(event == "onSpawnNote" && args.length == 1 && args[0].spawned, "HScript spawn arguments");
        events.push("hscript:" + args[0].id);
        hscriptAction(args[0]);
    }
    function invalidateNote(note:Note) {
        note.exists = false;
        notes.members.remove(note); // FlxTypedGroup.remove(note, true) contracts the array.
    }
    function goodNoteHit(note:Note) { if (!note.isSustainNote) invalidateNote(note); }
    function opponentNoteHit(note:Note) {
        note.hitByOpponent = true;
        if (!note.isSustainNote) invalidateNote(note);
    }
    function noteMiss(note:Note) misses++;
    function spawn() { @SPAWN@ }
    function updateNotes() {
        var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
        var i:Int = 0;
        @LOOP@
    }
    static function defaultFPS():Int { @DEFAULT@ return framerate; }
    function loadPrefs() { var data = ClientPrefs.data; @PREFS@ }
    function watch() { @WATCH@ }
    static function testPrefs() {
        var expected = #if mobile 60 #else 90 #end;
        check(defaultFPS() == expected, "new preference default");
        var option = {minValue: 0, maxValue: 0, defaultValue: 0};
        @OPTION@
        check(option.minValue == 60 && option.maxValue == #if mobile 90 #else 240 #end, "FPS selection range");
        check(option.defaultValue == expected, "reset preference default");
        var fixture = new Fixture();
        for (saved in ([{}, {framerate: null}, {framerate: 90}, {framerate: 75}]:Array<Dynamic>)) {
            ClientPrefs.data = {framerate: defaultFPS(), autoPause: true, showFPS: false};
            FlxG.save.data = saved;
            fixture.loadPrefs();
            var wanted = saved.framerate == null ? expected : saved.framerate;
            check(ClientPrefs.data.framerate == wanted, "saved FPS retained / absent FPS defaulted");
            check(FlxG.drawFramerate == wanted && FlxG.updateFramerate == wanted, "draw/update FPS agree");
            check(FlxG.autoPause && !Main.fpsVar.visible, "other loaded preferences retained");
        }
        fixture.watch();
        check(FlxG.watch.entries.join(",") == #if debug "secShit:2,beatShit:8,stepShit:32" #else "" #end,
            "debug watch guard");
    }
    static function testSpawn() {
        // Normal queue, then reorder/removal by each of the two script callbacks.
        for (mode in 0...5) {
            var f = new Fixture();
            var a = new Note("a"), b = new Note("b"), future = new Note("future");
            future.strumTime = 100;
            f.unspawnNotes = [a, b, future];
            var action = function(n:Note) {
                if (n != a) return;
                f.unspawnNotes.remove(n);
                if (mode == 1 || mode == 3) f.unspawnNotes.push(n);
            };
            if (mode == 1 || mode == 2) f.luaAction = action;
            if (mode == 3 || mode == 4) f.hscriptAction = action;
            f.spawn();
            check(f.unspawnNotes.length == 1 && f.unspawnNotes[0] == future, "future note survives callback mutation");
            check(f.notes.members.length == 2 && f.notes.members[0] == b && f.notes.members[1] == a, "spawn order");
            check(f.events.join(",") == "lua:a,hscript:a,lua:b,hscript:b", "callback order and exactly-once dispatch");
        }
    }
    static function testNulls() {
        var f = new Fixture();
        f.updateNotes();
        f.notes.members = [null, null];
        f.updateNotes();
        var a = new Note("a"), b = new Note("b");
        f.notes.members = [null, a, null, b, null];
        f.updateNotes();
        check(a.visits == 1 && b.visits == 1 && f.notes.length == 5, "null slots do not stall or remove live notes");
    }
    static function testKilled() {
        var f = new Fixture();
        var a = new Note("killed"), b = new Note("live");
        a.exists = false;
        f.notes.members = [a, b];
        f.updateNotes();
        check(a.visits == 1 && b.visits == 1 && f.notes.length == 2, "retained killed note does not stall");
    }
    static function testRemoval() {
        for (mode in 0...3) {
            var f = new Fixture();
            var a = new Note("a"), b = new Note("b"), tail = new Note("tail");
            if (mode == 0) { a.strumTime = -1000; b.strumTime = -1000; }
            if (mode == 1) { f.cpuControlled = true; tail.blockHit = true; }
            if (mode == 2) { a.mustPress = b.mustPress = false; a.wasGoodHit = b.wasGoodHit = true; }
            f.notes.members = [a, b, tail];
            f.updateNotes();
            check(a.visits == 1 && b.visits == 1 && tail.visits == 1, "removal processes shifted notes once");
            check(f.notes.length == 1 && f.notes.members[0] == tail, "only the surviving note remains");
            check(f.misses == (mode == 0 ? 2 : 0), "late-note misses preserved");
        }
        var f = new Fixture();
        var sustain = new Note("sustain");
        sustain.isSustainNote = true;
        f.cpuControlled = true;
        f.notes.members = [sustain];
        f.updateNotes();
        check(sustain.visits == 1 && sustain.clips == 1 && sustain.exists, "sustain note retained and clipped");
    }
    static function main() {
        var cases = Sys.args();
        var selected = cases.length == 0 ? "all" : cases[0];
        if (selected == "all" || selected == "prefs") testPrefs();
        if (selected == "all" || selected == "spawn") testSpawn();
        if (selected == "all" || selected == "nulls") testNulls();
        if (selected == "all" || selected == "killed") testKilled();
        if (selected == "all" || selected == "removal") testRemoval();
        Sys.println("PASS: " + selected + ", " + assertions + " assertions");
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--haxe", default="haxe")
    parser.add_argument("--source-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--case", choices=["all", "prefs", "spawn", "nulls", "killed", "removal"], default="all")
    args = parser.parse_args()
    root = args.source_root
    prefs = (root / "source/backend/ClientPrefs.hx").read_text()
    graphics = (root / "source/options/GraphicsSettingsSubState.hx").read_text()
    play = (root / "source/states/PlayState.hx").read_text()
    default = re.search(r"public var framerate:Int = .*?;", prefs).group().replace("public ", "", 1)
    load_start = prefs.index("for (key in Reflect.fields(data))", prefs.index("public static function loadPrefs()"))
    load_end = prefs.index("if(FlxG.save.data.gameplaySettings != null)", load_start)
    watch_start = play.rfind("\n\n", 0, play.index('FlxG.watch.addQuick("secShit"'))
    substitutions = {
        "DEFAULT": default,
        "PREFS": prefs[load_start:load_end],
        "OPTION": graphics[graphics.index("option.minValue = 60;"):graphics.index("option.displayFormat = '%v FPS';")],
        "WATCH": play[watch_start:play.index("// RESET = Quick Game Over Screen", watch_start)],
        "SPAWN": block(play, "if (unspawnNotes[0] != null)"),
        "LOOP": block(play, "while(i < notes.length)"),
    }
    source = TEMPLATE
    for name, value in substitutions.items():
        source = source.replace(f"@{name}@", value)
    with tempfile.TemporaryDirectory(prefix="psych-optimization-v1-") as directory:
        Path(directory, "Fixture.hx").write_text(source)
        for mobile, debug in [(False, False), (True, False), (False, True), (True, True)]:
            command = [args.haxe, "-cp", directory]
            if mobile:
                command += ["-D", "mobile"]
            if debug:
                command += ["-debug"]
            command += ["--run", "Fixture", args.case]
            print(f"mobile={mobile}, debug={debug}", flush=True)
            # A regression in the null-slot path otherwise never terminates.
            subprocess.run(command, check=True, timeout=10)


if __name__ == "__main__":
    main()
