package states.editors.content;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;

import haxe.Exception;
import sys.io.File;
import lime.ui.*;

import flixel.FlxBasic;

#if android
import lime.system.JNI;
#end

//Currently only supports OPEN and SAVE, might change that in the future, who knows
class FileDialogHandler extends FlxBasic
{
	static var pending:Int = 0;
	public static var isBusy(get, never):Bool;
	static function get_isBusy():Bool return pending > 0;
	function finish() { if(!completed) pending--; completed = true; }

	var _fileRef:FileReferenceCustom;
	var _dialogMode:FileDialogType = OPEN;
	public function new()
	{
		_fileRef = new FileReferenceCustom();
		_fileRef.addEventListener(Event.CANCEL, onCancelFn);
		_fileRef.addEventListener(IOErrorEvent.IO_ERROR, onErrorFn);
		
		#if android
		_androidCallback = {
			onFileSelected: function(rawData:String, fileName:String):Void { if(exists) onFileCompleteA(rawData, fileName); },
			onFileSaved: function(fileName:String):Void { if(exists) onSaveCompleteA(fileName); },
			onFileCancelled: function():Void { if(exists) onCancelA(); },
			onFileError: function():Void { if(exists) onErrorA(); }
		};
		#end

		super();
	}

	// callbacks
	public var onComplete:Void->Void;
	public var onCancel:Void->Void;
	public var onError:Void->Void;

	var _currentEvent:openfl.events.Event->Void;

	#if android
	private static var _browseFiles = JNI.createStaticMethod('mobile.backend.java.FileUtils', 'browseFiles', '(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V');
	private static var _browseBinary = JNI.createStaticMethod('mobile.backend.java.FileUtils', 'browseBinaryFiles', '(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V');
	private static var _saveFile = JNI.createStaticMethod('mobile.backend.java.FileUtils', 'saveFile', '(Ljava/lang/String;Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V');
	var _androidCallback:Dynamic;
	#end

	public function save(?fileName:String = '', ?dataToSave:String = '', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		#if android
		saveAndroid(fileName, dataToSave, onComplete, onCancel, onError); return;
		#end
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		this._dialogMode = SAVE;
		_startUp(onComplete, onCancel, onError);

		removeEvents();
		_currentEvent = onSaveComplete;
		_fileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		_fileRef.save(dataToSave, fileName);
	}

	public function open(?defaultName:String = null, ?title:String = null, ?filter:Array<FileFilter> = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		#if android
		openFiles('application/json', onComplete, onCancel, onError); return;
		#end
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		this._dialogMode = OPEN;
		_startUp(onComplete, onCancel, onError);
		if(filter == null) filter = [new FileFilter('JSON', 'json')];
		#if mac
		filter = [];
		#end

		removeEvents();
		_currentEvent = onLoadComplete;
		_fileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		_fileRef.browseEx(OPEN, defaultName, title, filter);
	}

	#if android
	public function openFiles(?mimeType:String = 'application/json', ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void):Void
	{
		if(!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_startUp(onComplete, onCancel, onError);
		_browseFiles(mimeType, _androidCallback);
	}

	/** Binary content is returned as Base64 in data; never decode an image as UTF-8. */
	public function openBinary(mimeType:String, onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		_startUp(onComplete, onCancel, onError);
		_browseBinary(mimeType, _androidCallback);
	}

	public function saveAndroid(fileName:String, dataToSave:String, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void):Void
	{
		if(!completed)
			throw new Exception('You must finish previous operation before starting a new one.');

		_dialogMode = SAVE;
		_startUp(onComplete, onCancel, onError);
		_saveFile(haxe.io.Path.withoutDirectory(fileName.replace('\\','/')), dataToSave, _androidCallback);
	}
	#end

	public function openDirectory(?title:String = null, ?onComplete:Void->Void, ?onCancel:Void->Void, ?onError:Void->Void)
	{
		if(!completed)
		{
			throw new Exception('You must finish previous operation before starting a new one.');
		}

		this._dialogMode = OPEN_DIRECTORY;
		_startUp(onComplete, onCancel, onError);

		removeEvents();
		_currentEvent = onLoadDirectoryComplete;
		_fileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		if(!_fileRef.browseEx(OPEN_DIRECTORY, null, title)) onErrorFn(null);
	}

	public var data:String;
	public var path:String;
	public var completed:Bool = true;
	function onSaveComplete(_)
	{
		@:privateAccess
		this.path = _fileRef._trackSavedPath;
		finish();
		trace('Saved file to: $path');

		removeEvents();
		if(onComplete != null) onComplete();
	}

	function onLoadComplete(_)
	{
		@:privateAccess
		this.path = _fileRef.__path;
		this.data = File.getContent(this.path);
		finish();
		trace('Loaded file from: $path');

		removeEvents();
		if(onComplete != null)
			onComplete();
	}

	function onLoadDirectoryComplete(_)
	{
		@:privateAccess
		this.path = _fileRef.__path;
		finish();
		trace('Loaded directory: $path');

		removeEvents();
		if(onComplete != null)
			onComplete();
	}

	function onCancelFn(_)
	{
		removeEvents();
		finish();
		if(onCancel != null) onCancel();
	}

	function onErrorFn(_)
	{
		removeEvents();
		finish();
		if(onError != null) onError();
	}

	#if android
	function onFileCompleteA(rawData:String, fileName:String):Void
	{
		data = rawData;
		path = fileName;
		finish();
		if(onComplete != null) onComplete();
	}

	function onSaveCompleteA(fileName:String):Void
	{
		path = fileName;
		finish();
		trace('Saved file to: $path');
		if(onComplete != null) onComplete();
	}

	function onCancelA():Void
	{
		finish();
		if(onCancel != null) onCancel();
	}

	function onErrorA():Void
	{
		finish();
		if(onError != null) onError();
	}
	#end

	function _startUp(onComplete:Void->Void, onCancel:Void->Void, onError:Void->Void)
	{
		if(isBusy) throw new Exception('A file picker is already open.');
		pending++;
		this.onComplete = onComplete;
		this.onCancel = onCancel;
		this.onError = onError;
		this.completed = false;

		this.data = null;
		this.path = null;
	}

	function removeEvents()
	{
		if(_currentEvent == null) return;
		
		_fileRef.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, _currentEvent);
		_currentEvent = null;
	}

	override function destroy()
	{
		removeEvents();
		_fileRef = null;
		_currentEvent = null;
		onComplete = null;
		onCancel = null;
		onError = null;
		data = null;
		path = null;
		#if android
		_androidCallback = null;
		#end
		finish();
		super.destroy();
	}
}

//Only way I could find to keep the path after saving a file
class FileReferenceCustom extends FileReference
{
	@:allow(backend.FileDialogHandler)
	var _trackSavedPath:String;
	override function saveFileDialog_onSelect(path:String):Void
	{
		_trackSavedPath = path;
		super.saveFileDialog_onSelect(path);
	}
	
	public function browseEx(browseType:FileDialogType = OPEN, ?defaultName:String, ?title:String = null, ?typeFilter:Array<FileFilter> = null):Bool
	{
		__data = null;
		__path = null;

		#if desktop
		var filter = null;

		if (typeFilter != null)
		{
			var filters = [];

			for (type in typeFilter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", ""), ";", ","));
			}

			filter = filters.join(";");
		}

		var openFileDialog = new FileDialog();
		openFileDialog.onCancel.add(openFileDialog_onCancel);
		openFileDialog.onSelect.add(openFileDialog_onSelect);
		openFileDialog.browse(browseType, filter, defaultName, title);
		return true;
		#elseif (js && html5)
		var filter = null;
		if (typeFilter != null)
		{
			var filters = [];
			for (type in typeFilter)
			{
				filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", "."), ";", ","));
			}
			filter = filters.join(",");
		}
		if (filter != null)
		{
			__inputControl.setAttribute("accept", filter);
		}
		__inputControl.onchange = function()
		{
			var file = __inputControl.files[0];
			modificationDate = Date.fromTime(file.lastModified);
			creationDate = modificationDate;
			size = file.size;
			type = "." + Path.extension(file.name);
			name = Path.withoutDirectory(file.name);
			__path = file.name;
			dispatchEvent(new Event(Event.SELECT));
		}
		__inputControl.click();
		return true;
		#end

		return false;
	}
}