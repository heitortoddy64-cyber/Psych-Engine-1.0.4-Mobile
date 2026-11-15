package backend;

#if macro
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
import haxe.crypto.Sha256;

/** Fail the build before packaging if the Lite Tutorial reference is incomplete. */
class LiteAssets
{
 public static function validate()
 {
  var manifest:Dynamic=haxe.Json.parse(File.getContent('docs/V2_ASSET_MANIFEST.json'));
  var protectedFiles:Array<Dynamic>=manifest.protected;
  for(entry in protectedFiles) check(entry.path,entry.sha256);
  var moved:Array<Dynamic>=manifest.relocated;
  for(entry in moved) check(entry.to,entry.sha256);
  var week:Dynamic=haxe.Json.parse(File.getContent('assets/base_game/shared/weeks/tutorial.json'));
  if(week.songs==null || week.songs.length!=1 || week.songs[0][0]!='Tutorial') fail('Invalid Tutorial week');
  if(StringTools.trim(File.getContent('assets/shared/weeks/weekList.txt'))!='tutorial') fail('Built-in week list must contain Tutorial');
  var stage:Dynamic=haxe.Json.parse(File.getContent('assets/base_game/shared/stages/stage.json'));
  if(stage.directory!='shared') fail('Tutorial must use the preserved shared stage assets');
  for(difficulty in ['tutorial','tutorial-easy','tutorial-hard','events'])
   haxe.Json.parse(File.getContent('assets/base_game/shared/data/tutorial/'+difficulty+'.json'));
 }
 static function check(path:String,hash:String)
 {
  if(!FileSystem.exists(path)) fail('Missing Lite asset: '+path);
  if(Sha256.make(File.getBytes(path)).toHex()!=hash) fail('Protected Lite asset changed: '+path);
 }
 static function fail(message:String) Context.fatalError(message,Context.currentPos());
}
#end
