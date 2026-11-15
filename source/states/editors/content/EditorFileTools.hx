package states.editors.content;

#if android
import haxe.io.Path;
import haxe.crypto.Base64;
import states.editors.content.Prompt;

class EditorFileTools
{
 /** Import into the selected mod only; SAF names cannot escape the images directory. */
 public static function importImage(dialog:FileDialogHandler, onImported:String->Void, onError:String->Void)
 {
  if(FileDialogHandler.isBusy) return;
  dialog.openBinary('*/*', function()
  {
   try
   {
    var name=Path.withoutDirectory(dialog.path.replace('\\','/'));
    var ext=Path.extension(name).toLowerCase();
    if(!['png','xml','json','txt'].contains(ext)) throw 'Choose PNG, XML, JSON or TXT.';
    var stem=Path.withoutExtension(name);
    if(!~/^[a-zA-Z0-9_-]+$/.match(stem)) throw 'Use an image filename containing only letters, digits, _ or -.';
    var folder=Paths.mods((Mods.currentModDirectory.length>0?Mods.currentModDirectory+'/':'')+'images/');
    var target=folder+stem+'.'+ext;
    var bytes=Base64.decode(dialog.data);
    function write()
    {
     try { FileSystem.createDirectory(folder);File.saveBytes(target,bytes);onImported(stem); }
     catch(e:Dynamic) onError('Import failed: '+Std.string(e));
    }
    // Existing files require an explicit confirmation; a drag never overwrites a mod asset.
    if(FileSystem.exists(target)) FlxG.state.openSubState(new Prompt('Replace '+name+' in the selected mod?',write));
    else write();
   }
   catch(e:Dynamic) onError(Std.string(e));
  }, null, function() onError('Android could not read this document.'));
 }
}
#end
