#!/usr/bin/env python3
"""Run actual editor input/routing code with headless framework stand-ins.

Checks command/capture lifecycle, not rendering, OS touch delivery, real IME or SAF.
"""
from pathlib import Path
import tempfile,subprocess,shutil
ROOT=Path(__file__).resolve().parents[1]
FILES={
'import.hx':'''import support.Stubs; import backend.ui.*;''',
'flixel/FlxBasic.hx':'''package flixel; class FlxBasic { public var exists=true;public var active=true;public var visible=true;public var alpha:Float=1;public var cameras:Array<support.Stubs.FlxCamera>;public function new(){} public function update(e:Float){}public function destroy(){exists=false;} }''',
'flixel/input/keyboard/FlxKey.hx':'''package flixel.input.keyboard; enum abstract FlxKey(Int) from Int to Int {var ESCAPE=27;var ALT=18;var SHIFT=16;var CONTROL=17;var ENTER=13;var UP=38;var DOWN=40;var LEFT=37;var RIGHT=39;var W=87;var C=67;var DELETE=46;public static function fromString(v:String):FlxKey {if(v.length==1)return v.charCodeAt(0);return switch(v){case 'ESCAPE':27;case 'SHIFT':16;case 'CONTROL':17;case 'ENTER':13;case 'UP':38;case 'DOWN':40;case 'LEFT':37;case 'RIGHT':39;case 'DELETE':46;default:200+v.length;};}}''',
'flixel/input/FlxInput.hx':'''package flixel.input; enum abstract FlxInputState(Int) from Int {var JUST_PRESSED=2;var PRESSED=1;var JUST_RELEASED=-1;var RELEASED=0;}''',
'flixel/input/FlxPointer.hx':'''package flixel.input; import support.Stubs; class FlxPointer {public var x:Int;public var y:Int;public var screenX:Int;public var screenY:Int;public function new(x=0,y=0){this.x=screenX=x;this.y=screenY=y;}public function getScreenPosition(?c:FlxCamera,?p:FlxPoint):FlxPoint return new FlxPoint(screenX,screenY);public function getWorldPosition(?c:FlxCamera,?p:FlxPoint):FlxPoint return getScreenPosition(c,p);public function getPositionInCameraView(?c:FlxCamera,?p:FlxPoint):FlxPoint return getScreenPosition(c,p);public function overlaps(b:flixel.FlxBasic,?c:FlxCamera):Bool return false;}''',
'flixel/input/touch/FlxTouch.hx':'''package flixel.input.touch; class FlxTouch extends flixel.input.FlxPointer {public var touchPointID:Int;public var pressed=true;public var justPressed=true;public var justReleased=false;public function new(x,y,id){super(x,y);touchPointID=id;}}''',
'states/editors/content/FileDialogHandler.hx':'''package states.editors.content; class FileDialogHandler {public static var isBusy=false;}''',
'support/Stubs.hx':'''package support;
import flixel.FlxBasic;
class Stubs {}
class FlxPoint {public var x:Float;public var y:Float;public function new(x:Float=0,y:Float=0){set(x,y);}public function set(x:Float=0,y:Float=0){this.x=x;this.y=y;return this;}}
class FlxCamera {public var bgColor:Int=0;public var zoom:Float=1;public var scroll=new FlxPoint();public function new(){}}
class FlxSprite extends FlxBasic {public var x:Float;public var y:Float;public var width:Float=0;public var height:Float=0;public var scrollFactor=new FlxPoint();public function new(x:Float=0,y:Float=0){super();this.x=x;this.y=y;} public function makeGraphic(w:Int,h:Int,color:Int){width=w;height=h;return this;} }
class FlxSpriteGroup extends FlxSprite {public var members:Array<FlxSprite>=[];public function new(){super();}public function add(s:FlxSprite){members.push(s);return s;}public function remove(s:FlxSprite,splice:Bool){members.remove(s);return s;}}
enum abstract FlxTextAlign(String) {var CENTER="center";}
class FlxText extends FlxSprite {public var alignment:FlxTextAlign;public function new(x:Float,y:Float,w:Float,t:String,size:Int){super(x,y);width=w;}}
class PsychUIBox extends FlxSpriteGroup {}
class PsychUIButton extends FlxSpriteGroup {}
class PsychUICheckBox extends FlxSpriteGroup {}
class PsychUISlider extends FlxSpriteGroup {}
class PsychUIRadioGroup extends FlxSpriteGroup {}
class PsychUIInputText extends FlxSpriteGroup {public static var focusOn:PsychUIInputText;}
class MusicBeatState {public var virtualPad:FlxSprite;public var members:Array<FlxSprite>=[];public var subState:Dynamic;public function new(){}public function add(s:FlxSprite){members.push(s);return s;}}
class FlxMath {public static function wrap(v:Int,a:Int,b:Int):Int return v<a?b:v>b?a:v;}
class Signal {var callbacks:Array<Void->Void>=[];public function new(){}public function add(f:Void->Void)callbacks.push(f);public function remove(f:Void->Void)callbacks.remove(f);public function dispatch(){for(f in callbacks)f();}}
class Cameras {public var list:Array<FlxCamera>=[];public function new(){}public function add(c:FlxCamera,b:Bool){list.push(c);return c;}public function remove(c:FlxCamera,b:Bool)list.remove(c);}
class Plugins {public var list:Array<FlxBasic>=[];public function new(){}public function add<T:FlxBasic>(p:T):T{list.push(p);return p;}public function remove<T:FlxBasic>(p:T):T{list.remove(p);return p;}public function update(){for(p in list.copy())p.update(FlxG.elapsed);}}
class Mouse extends flixel.input.FlxPointer {public var visible=true;public var pressed=false;public var justPressed=false;public var justReleased=false;public var released=true;public var pressedRight=false;public var justPressedRight=false;public var justReleasedRight=false;public var justMoved=false;public var deltaScreenX=0;public var deltaScreenY=0;public var wheel=0;public function new(){super();}}
class Keyboard {public function new(){}public function checkStatus(k:flixel.input.keyboard.FlxKey,s:flixel.input.FlxInput.FlxInputState):Bool return false;}
class FlxG {public static var height=720;public static var elapsed:Float=1/60;public static var cameras=new Cameras();public static var plugins=new Plugins();public static var signals={focusLost:new Signal(),focusGained:new Signal()};public static var touches:{list:Array<flixel.input.touch.FlxTouch>}={list:[]};public static var android={justReleased:{BACK:false}};public static var keys=new Keyboard();public static var mouse=new Mouse();}
''',
'Routing.hx':'''import mobile.controls.EditorTouchControls;import flixel.input.touch.FlxTouch;import flixel.input.keyboard.FlxKey;import states.editors.content.FileDialogHandler;
@:access(mobile.controls.EditorTouchControls)
class Routing {
 static var assertions=0;
 static function check(ok:Bool,label:String){assertions++;if(!ok)throw label;}
 static function frame(touches:Array<FlxTouch>){FlxG.touches.list=touches;FlxG.plugins.update();}
 static function hold(t:FlxTouch){t.justPressed=false;return t;}
 static function release(t:FlxTouch){t.justPressed=false;t.justReleased=true;t.pressed=false;return t;}
 static function tap(c:EditorTouchControls,label:String,id:Int){var box=c.boxes.filter(b->b.action!=null && b.action.label==label)[0];var t=new FlxTouch(Std.int(box.x+30),Std.int(box.y+25),id);frame([t]);frame([release(t)]);}
 static function main(){
  var state=new MusicBeatState();var panel=new PsychUIBox();panel.scrollFactor.set();state.add(panel);EditorTouchControls.install(state,'Chart');var c:EditorTouchControls=cast state.members[1];
  check(panel.scrollFactor.x==1&&panel.scrollFactor.y==1&&panel.cameras[0]==c.ui,'dedicated HUD camera can pan panel');
  check(FlxG.plugins.list.length==1,'one plugin');
  FlxG.mouse.justPressed=true;frame([]);check(EditorPointer.justPressed&&!EditorInput.touchActive,'idle hardware mouse retained');FlxG.mouse.justPressed=false;
  var first=new FlxTouch(900,300,1);frame([first]);check(EditorPointer.justPressed && c.primary==1,'capture primary');
  var second=new FlxTouch(930,310,2);frame([hold(first),second]);check(c.primary==1 && EditorInput.touch==first,'second canvas finger never steals');
  first.screenX=920;frame([first,hold(second)]);check(EditorPointer.dx==20,'drag delta');
  frame([release(first),second]);check(EditorPointer.justReleased && c.primary==-1,'release ends capture');frame([second]);check(c.primary==-1,'no midgesture handoff');
  c.expanded=true;c.page=2;c.rebuild();
  var box=c.boxes.filter(b->b.action!=null && b.action.label=='Copy')[0];var copy=new FlxTouch(Std.int(box.x+30),Std.int(box.y+25),3);
  FlxG.mouse.justPressed=true;frame([copy]);check(!EditorPointer.justPressed,'toolbar touch suppresses emulated mouse');FlxG.mouse.justPressed=false;check(!EditorInput.keys.pressed(67),'copy waits for release');frame([release(copy)]);check(EditorInput.keys.justPressed(67)&&EditorInput.keys.pressed(17),'copy combo on release');frame([]);check(!EditorInput.keys.pressed(67)&&EditorInput.keys.justReleased(67),'copy releases');
  c.page=2;c.rebuild();box=c.boxes.filter(b->b.action!=null && b.action.label=='Delete')[0];var deletion=new FlxTouch(Std.int(box.x+30),Std.int(box.y+25),30);frame([deletion]);check(!EditorInput.keys.pressed(46),'delete waits for release');deletion.screenX+=100;frame([release(deletion)]);check(!EditorInput.keys.pressed(46),'dragged release never deletes');frame([]);
  c.page=1;c.rebuild();box=c.boxes.filter(b->b.action!=null && b.action.label=='Scrub back')[0];var movement=new FlxTouch(Std.int(box.x+30),Std.int(box.y+25),4);
  frame([movement]);check(EditorInput.keys.pressed(87),'hold movement');frame([hold(movement)]);check(!EditorInput.keys.justPressed(87),'hold is not repeated immediately');FlxG.elapsed=0.6;frame([movement]);check(EditorInput.keys.justPressed(87),'long hold repeats');FlxG.elapsed=1/60;frame([]);check(!EditorInput.keys.pressed(87),'lost movement finger releases');
  // Changing page while a second finger holds a control must cancel that old contact.
  movement=new FlxTouch(Std.int(box.x+30),Std.int(box.y+25),5);frame([movement]);c.page=2;c.rebuild();frame([hold(movement)]);check(!EditorInput.keys.pressed(87)&&!EditorInput.keys.pressed(46),'page switch cancels contacts');
  EditorPointer.cancelled=false;c.pointerMode=2;var select=new FlxTouch(900,300,6);frame([select]);check(EditorInput.keys.pressed(16),'select modifier');c.rebuild();check(EditorPointer.cancelled&&!EditorPointer.touchDown&&c.primary==-1,'layout cancels drag');frame([hold(select)]);check(!EditorInput.keys.pressed(16),'cancelled canvas cannot retain modifier');
  c.pointerMode=0;c.panUI=true;var pan=new FlxTouch(800,300,7);frame([pan]);pan.screenX=830;frame([hold(pan)]);check(EditorPointer.blocked&&c.ui.scroll.x==-30,'UI pan blocks editing');frame([release(pan)]);c.panUI=false;
  FileDialogHandler.isBusy=true;frame([new FlxTouch(900,300,8)]);check(EditorPointer.blocked&&c.primary==-1&&!EditorInput.keys.pressed(87),'SAF blocks/cancels');FileDialogHandler.isBusy=false;frame([]);
  PsychUIInputText.focusOn=new PsychUIInputText();frame([]);check(c.boxes.length==1,'IME relinquishes toolbar');FlxG.android.justReleased.BACK=true;frame([]);check(PsychUIInputText.focusOn==null&&!EditorInput.backPressed(),'IME Back never exits editor');FlxG.android.justReleased.BACK=false;frame([]);frame([]);
  c.page=1;c.expanded=true;c.rebuild();box=c.boxes.filter(b->b.action!=null && b.action.label=='Scrub back')[0];movement=new FlxTouch(Std.int(box.x+30),Std.int(box.y+25),9);frame([movement]);FlxG.signals.focusLost.dispatch();check(!EditorInput.keys.pressed(87)&&c.primary==-1,'focus loss clears');
  c.precise=true;frame([]);check(EditorInput.keys.pressed(18)&&!EditorInput.keys.pressed(17),'Chart fine seek uses Alt, not move modifier');c.precise=false;
  c.destroy();check(FlxG.plugins.list.length==0&&FlxG.cameras.list.length==0&&!EditorInput.active,'destroy removes input plugin/cameras');
  for(profile in ['Character','Stage','Portrait','Splash','Menu Character','Dialogue','Week','Master']) {
   var nextState=new MusicBeatState();EditorTouchControls.install(nextState,profile);var toolbar:EditorTouchControls=cast nextState.members[0];
   check(!Lambda.exists(toolbar.pages[0].actions,a->a.label=='Select/tap'||a.label=='Move/tap'),'note-only modes hidden in '+profile);
   check(toolbar.allowPrecise==(['Character','Stage'].contains(profile)),'precision command exists in '+profile);
   check(toolbar.allowFast==(['Character','Stage','Portrait','Splash','Menu Character'].contains(profile)),'fast command exists in '+profile);
   toolbar.destroy();
  }
  Sys.println('PASS: '+assertions+' actual editor routing assertions with headless framework stand-ins; no device/UI test');
 }
}'''
}
with tempfile.TemporaryDirectory(prefix='psych-routing-') as directory:
 work=Path(directory)
 for path,contents in FILES.items():
  p=work/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(contents)
 for path in ['mobile/controls/EditorTouchControls.hx','backend/ui/EditorKeyState.hx','backend/ui/EditorInput.hx','backend/ui/EditorPointer.hx']:
  p=work/path;p.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/'source'/path,p)
 subprocess.run(['haxe','-cp',str(work),'-D','mobile','-D','android','-main','Routing','--interp'],check=True)
