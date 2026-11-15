package mobile.controls;

#if mobile
import flixel.FlxBasic;
import flixel.input.keyboard.FlxKey;

private typedef EditorAction = {
 var label:String;
 var keys:Array<FlxKey>;
 var hold:Bool;
}

/** Editor-only touch commands. Never injects events into the Android keyboard. */
class EditorTouchControls extends FlxSpriteGroup
{
 var owner:MusicBeatState;
 var hud:FlxCamera;
 var ui:FlxCamera;
 var pages:Array<{name:String, actions:Array<EditorAction>}> = [];
 var page:Int = 0;
 var expanded:Bool = false;
 var dockTop:Bool = false;
 var pointerMode:Int = 0;
 var fast:Bool = false;
 var precise:Bool = false;
 var panUI:Bool = false;
 var contacts:Map<Int, {button:Int, x:Float, y:Float, time:Float, tick:Int}> = [];
 var primary:Int = -1;
 var lastX:Float = 0;
 var lastY:Float = 0;
 var oldFocus:Bool = false;
 var modal:Bool=false;
 var wasBlocked:Bool=false;
 var inputPlugin:EditorTouchInputPlugin;
 var boxes:Array<{x:Float,y:Float,w:Float,h:Float,run:Void->Void,action:EditorAction}> = [];

 public static function install(state:MusicBeatState, profile:String)
 {
  // Legacy pads stay allocated for the original state lifecycle, but no longer intercept touches.
  if(state.virtualPad != null) { state.virtualPad.visible = false; state.virtualPad.active = false; }
  state.add(new EditorTouchControls(state, profile));
 }

 function new(state:MusicBeatState, profile:String)
 {
  super(); owner = state;
  ui = new FlxCamera(); ui.bgColor = 0; FlxG.cameras.add(ui, false);
  for(member in state.members) if(member != null && containsUI(member)) bindPanel(cast member);
  hud = new FlxCamera(); hud.bgColor = 0; FlxG.cameras.add(hud, false); cameras = [hud];
  scrollFactor.set();
  addPage('VIEW', ['Edit/tap:', 'Drag/right:', 'Select/tap:', 'Move/tap:', 'UI pan:', 'UI zoom:', 'Reset UI:', 'Dock:']);
  switch(profile)
  {
   case 'Chart':
    addPage('PLAY', ['Play / pause:SPACE','Test chart:ENTER','Scrub back:W','Scrub forward:S','Section back:A','Section next:D','Song start:HOME','Song end:END']);
    addPage('NOTES', ['Delete:DELETE','Select all:CONTROL+A','Copy:CONTROL+C','Paste:CONTROL+V','Cut:CONTROL+X','Undo:CONTROL+Z','Redo:CONTROL+Y','Save:CONTROL+S']);
    addPage('TIMING', ['Hold shorter:Q','Hold longer:E','Quantize -:LEFT','Quantize +:RIGHT','Zoom out:Z','Zoom in:X','Speed -:LBRACKET','Speed +:RBRACKET']);
    addPage('VORTEX', ['Lane 1:ONE','Lane 2:TWO','Lane 3:THREE','Lane 4:FOUR','Lane 5:FIVE','Lane 6:SIX','Lane 7:SEVEN','Lane 8:EIGHT']);
    addPage('TOOLS', ['Reset section:R','Help:F1','Preview:F12','Scroll up:','Scroll down:','Fast:', 'Precise:', 'Reset speed:ALT+LBRACKET']);
   case 'Character', 'Stage', 'Portrait':
    addPage('CAMERA', ['Pan left:J','Pan right:L','Pan up:I','Pan down:K','Zoom out:Q','Zoom in:E','Reset view:R','Fast:']);
    addPage('OFFSETS', ['Offset left:LEFT','Offset right:RIGHT','Offset up:UP','Offset down:DOWN','Fast:','Precise:']);
    if(profile=='Character') {
     addPage('ANIMATION', ['Animation back:W','Animation next:S','Replay:SPACE','Frame back:A','Frame next:D','Ghost:F12','Help:F1']);
     addPage('OFFSET TOOLS', ['Copy:CONTROL+C','Paste:CONTROL+V','Reset:CONTROL+R','Undo:CONTROL+Z']);
    }
    if(profile=='Portrait') addPage('ANIMATION', ['Animation back:W','Animation next:S','Replay:SPACE','Ghost / bubble:H']);
    if(profile=='Stage') addPage('ANIMATION', ['Animation back:W','Animation next:S','Replay:SPACE','Reset offset:CONTROL+R','Help:F1']);
    if(profile == 'Portrait') addPage('LOOP OFFSET', ['Loop left:A','Loop right:D','Loop up:W','Loop down:S','Fast:','Precise:']);
    if(profile == 'Stage') addPage('STAGE', ['Sprite back:W','Sprite next:S','Toggle UI:F2','Toggle info:F3','Selection:F12','Fast:','Precise:','Help:F1']);
   case 'Dialogue':
    addPage('DIALOGUE', ['Line back:D','Line next:A','Animation back:W','Animation next:S','Replay:SPACE','Add line:O','Delete line:P']);
   case 'Splash':
    addPage('OFFSETS', ['Offset left:LEFT','Offset right:RIGHT','Offset up:UP','Offset down:DOWN','Replay:SPACE','Copy:CONTROL+C','Paste:CONTROL+V','Reset:CONTROL+R']);
    addPage('TOOLS', ['Fast:','Precise:','Help:F1','Scroll up:','Scroll down:']);
   case 'Menu Character':
    addPage('POSITION', ['Offset left:LEFT','Offset right:RIGHT','Offset up:UP','Offset down:DOWN','Replay:SPACE','Fast:']);
   case 'Week': // Metadata and file actions use the existing widgets.
   default:
    addPage('NAVIGATE', ['Up:UP','Down:DOWN','Left:LEFT','Right:RIGHT','Confirm:ENTER','Scroll up:','Scroll down:']);
  }
  EditorInput.reset(); EditorInput.active = true; EditorInput.touchActive = true;
  rebuild();
  // Plugins update after Flixel's input managers and before the state/substate.
  inputPlugin=FlxG.plugins.add(new EditorTouchInputPlugin(processFrame));
  FlxG.signals.focusLost.add(cancelInput);
  FlxG.signals.focusGained.add(cancelInput);
 }

 function containsUI(b:FlxBasic):Bool
 {
  if(Std.isOfType(b, PsychUIBox) || Std.isOfType(b, PsychUIButton) || Std.isOfType(b, PsychUIInputText)
   || Std.isOfType(b, PsychUICheckBox) || Std.isOfType(b, PsychUISlider) || Std.isOfType(b, PsychUIRadioGroup)) return true;
  if(Std.isOfType(b, FlxSpriteGroup))
   for(child in (cast b:FlxSpriteGroup).members) if(child != null && containsUI(child)) return true;
  return false;
 }

 function bindPanel(panel:FlxSprite)
 {
  panel.cameras=[ui];
  // HUD widgets originally ignore camera scroll. The dedicated UI camera must be pannable.
  panel.scrollFactor.set(1,1);
 }

 function addPage(name:String, definitions:Array<String>)
 {
  var actions:Array<EditorAction> = [];
  for(definition in definitions)
  {
   var split = definition.split(':'); var keys:Array<FlxKey> = [];
   if(split[1].length > 0) for(key in split[1].split('+')) keys.push(FlxKey.fromString(key));
   var hold = split[0].indexOf('Pan ') == 0 || split[0].indexOf('Scrub ') == 0 || split[0].indexOf('Zoom ') == 0
    || split[0].indexOf('Offset ') == 0 || split[0].indexOf('Hold ') == 0 || split[0].indexOf('Loop ') == 0;
   actions.push({label:split[0], keys:keys, hold:hold});
  }
  pages.push({name:name, actions:actions});
 }

 function button(x:Float,y:Float,w:Float,h:Float,label:String,run:Void->Void,?action:EditorAction)
 {
  var bg = new FlxSprite(x,y).makeGraphic(Std.int(w-3),Std.int(h-3),0xF0222938); add(bg);
  var text = new FlxText(x+2,y+8,w-7,label,18); text.alignment = CENTER; add(text);
  boxes.push({x:x,y:y,w:w,h:h,run:run,action:action});
 }

 function rebuild()
 {
  // A second finger must not inherit another page's button index after a layout change.
  contacts.clear();
  cancelPointer();
  while(members.length > 0) { var old = remove(members[0], true); old.destroy(); }
  boxes = [];
  var y = dockTop ? 0 : FlxG.height - (expanded ? 166 : 52);
  button(0,y,150,52,'BACK / DONE',function() {
   if(PsychUIInputText.focusOn != null) { PsychUIInputText.focusOn = null; EditorInput.ignoreBack = true; }
   else EditorInput.keys.hold(FlxKey.ESCAPE);
  });
  if(modal || PsychUIInputText.focusOn!=null) return;
  button(150,y,210,52,(expanded ? 'HIDE ' : 'TOUCH ') + pages[page].name,function() { expanded = !expanded; rebuild(); });
  button(360,y,100,52,'PAGE <',function() { page = FlxMath.wrap(page-1,0,pages.length-1); rebuild(); });
  button(460,y,100,52,'PAGE >',function() { page = FlxMath.wrap(page+1,0,pages.length-1); rebuild(); });
  button(560,y,270,52,(panUI?'UI PAN':'MODE '+['EDIT','DRAG','SELECT','MOVE'][pointerMode]),function() { pointerMode=(pointerMode+1)%4; rebuild(); });
  button(830,y,210,52,'FAST '+(fast?'ON':'OFF'),function(){ fast=!fast; rebuild(); });
  button(1040,y,240,52,'PRECISE '+(precise?'ON':'OFF'),function(){ precise=!precise; rebuild(); });
  if(!expanded) return;
  for(i => action in pages[page].actions)
  {
   var a = action;
   button((i%4)*320,y+52+Math.floor(i/4)*57,320,57,a.label,function() { command(a); },a);
  }
 }

 function command(a:EditorAction)
 {
  if(a.keys.length > 0) for(key in a.keys) EditorInput.keys.hold(key);
  else switch(a.label)
  {
   case 'Edit/tap': pointerMode=0;
   case 'Drag/right': pointerMode=1;
   case 'Select/tap': pointerMode=2;
   case 'Move/tap': pointerMode=3;
   case 'UI pan': panUI=!panUI;
   case 'UI zoom': ui.zoom = ui.zoom >= 4 ? 1 : ui.zoom+0.5;
   case 'Reset UI': ui.zoom=1; ui.scroll.set(); panUI=false;
   case 'Dock': dockTop=!dockTop;
   case 'Fast': fast=!fast;
   case 'Precise': precise=!precise;
   case 'Scroll up': EditorPointer.scroll=1;
   case 'Scroll down': EditorPointer.scroll=-1;
  }
  rebuild();
 }

 function processFrame()
 {
  EditorInput.keys.beginFrame(); EditorInput.ignoreBack=false;
  EditorPointer.touchStarted = EditorPointer.touchEnded = false;
  EditorPointer.dx=EditorPointer.dy=EditorPointer.scroll=0;
  EditorPointer.blocked=false;
  for(i in 0...boxes.length) members[i*2].alpha=1;
  // The UI camera needs to follow panels added after create (e.g. chart menus).
  if(owner.subState == null) for(member in owner.members)
   if(member != null && member != this && containsUI(member)) bindPanel(cast member);
  modal=owner.subState!=null && Type.getClassName(Type.getClass(owner.subState))!='states.editors.StageEditorAnimationSubstate';
  var focused = PsychUIInputText.focusOn != null;
  EditorInput.blockKeyboard=focused || oldFocus || states.editors.content.FileDialogHandler.isBusy;
  if(wasBlocked != (modal || focused)) { rebuild();wasBlocked=modal || focused; }
  if(focused || modal || states.editors.content.FileDialogHandler.isBusy)
  {
   EditorInput.keys.clear(); fast=precise=false;
   #if android
   if(focused && FlxG.android.justReleased.BACK) { PsychUIInputText.focusOn=null; EditorInput.ignoreBack=true; }
   #end
  }
  if(focused != oldFocus) { contacts.clear(); cancelPointer(); oldFocus=focused; }
  if(states.editors.content.FileDialogHandler.isBusy) { contacts.clear(); cancelPointer(); EditorPointer.blocked=true; return; }
  for(touch in FlxG.touches.list)
  {
   var id=touch.touchPointID;
   var pos=touch.getScreenPosition(hud);
   if(touch.justPressed)
   {
    var hit=-1;
    for(i => box in boxes) if(pos.x>=box.x && pos.x<box.x+box.w && pos.y>=box.y && pos.y<box.y+box.h) { hit=i; break; }
    if(hit >= 0) contacts.set(id,{button:hit,x:pos.x,y:pos.y,time:0,tick:0});
    else if(primary == -1) { primary=id; EditorInput.touch=touch; lastX=touch.screenX;lastY=touch.screenY; EditorPointer.touchStarted=true; EditorPointer.touchButton=pointerMode==1 && !modal && !focused?1:0; }
   }
   if(contacts.exists(id))
   {
    var contact=contacts.get(id);
    if(contact.button >= boxes.length) { contacts.remove(id); continue; }
    var box=boxes[contact.button];
    members[contact.button*2].alpha=0.65;
    if(!focused && box.action != null && box.action.hold && touch.pressed)
    {
     for(key in box.action.keys) EditorInput.keys.hold(key);
     contact.time += FlxG.elapsed;
     if(contact.time > 0.45 && Std.int((contact.time-0.45)*12)>contact.tick)
     { contact.tick++; for(key in box.action.keys) EditorInput.keys.repeat(key); }
    }
    if(touch.justReleased)
    {
     contacts.remove(id);
     if((!focused || contact.button==0) && Math.abs(pos.x-contact.x)<18 && Math.abs(pos.y-contact.y)<18
      && pos.x>=box.x && pos.x<box.x+box.w && pos.y>=box.y && pos.y<box.y+box.h
      && (box.action==null || !box.action.hold)) box.run();
    }
   }
   if(primary==id)
   {
    EditorInput.touch=touch;
    EditorPointer.touchDown=touch.pressed;
    EditorPointer.touchEnded=touch.justReleased;
    EditorPointer.dx=touch.screenX-lastX; EditorPointer.dy=touch.screenY-lastY;
    lastX=touch.screenX;lastY=touch.screenY;
    if(panUI && owner.subState==null && !focused) { ui.scroll.x-=EditorPointer.dx/ui.zoom;ui.scroll.y-=EditorPointer.dy/ui.zoom;EditorPointer.blocked=true; }
    else if(!focused && !modal) { if(pointerMode==2) EditorInput.keys.hold(FlxKey.SHIFT); if(pointerMode==3) EditorInput.keys.hold(FlxKey.CONTROL); }
    if(touch.justReleased) primary=-1;
   }
  }
  if(!focused && !modal) { if(fast) EditorInput.keys.hold(FlxKey.SHIFT); if(precise) EditorInput.keys.hold(FlxKey.CONTROL); }
  // A cancelled/lost contact must never retain a pointer or a command.
  if(primary>=0 && !Lambda.exists(FlxG.touches.list, function(t) return t.touchPointID==primary)) cancelPointer();
  var lost:Array<Int>=[];
  for(id in contacts.keys()) if(!Lambda.exists(FlxG.touches.list, function(t) return t.touchPointID==id)) lost.push(id);
  for(id in lost) contacts.remove(id);
 }

 function cancelInput()
 {
  contacts.clear();cancelPointer();fast=precise=false;
  EditorInput.keys.clear();EditorInput.touch=null;
 }

 function cancelPointer()
 {
  if(primary>=0) EditorPointer.cancelled=true;
  primary=-1;
  EditorPointer.touchDown=EditorPointer.touchStarted=EditorPointer.touchEnded=false;
  EditorPointer.dx=EditorPointer.dy=0;
 }

 override public function destroy()
 {
  FlxG.plugins.remove(inputPlugin);inputPlugin.destroy();inputPlugin=null;
  contacts.clear(); EditorInput.reset();
  FlxG.signals.focusLost.remove(cancelInput);FlxG.signals.focusGained.remove(cancelInput);
  if(FlxG.cameras.list.contains(ui)) FlxG.cameras.remove(ui,true);
  if(FlxG.cameras.list.contains(hud)) FlxG.cameras.remove(hud,true);
  owner=null; super.destroy();
 }
}

private class EditorTouchInputPlugin extends FlxBasic
{
 var poll:Void->Void;
 public function new(poll:Void->Void) {super();this.poll=poll;visible=false;}
 override public function update(elapsed:Float) poll();
 override public function destroy() {poll=null;super.destroy();}
}
#end
