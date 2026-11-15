package backend.ui;

import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;
#if mobile
import flixel.input.touch.FlxTouch;
#end

/** Editor-only commands. Desktop keyboard input always retains its original path. */
class EditorInput
{
	public static var active:Bool = false;
	public static var keys = new EditorKeyState();
	public static var ignoreBack:Bool = false;
	public static var blockKeyboard:Bool = false;
	#if mobile
	public static var touch:FlxTouch;
	public static var touchActive:Bool = false;
	#end
	public static function pressed(key:FlxKey):Bool
		return (!active || !blockKeyboard) && FlxG.keys.checkStatus(key, PRESSED) || (active && keys.pressed(key));
	public static function justPressed(key:FlxKey):Bool
		return (!active || !blockKeyboard) && !(active && ignoreBack && key == ESCAPE) && FlxG.keys.checkStatus(key, JUST_PRESSED) || (active && keys.justPressed(key)) || (key == ESCAPE && backPressed());
	public static function justReleased(key:FlxKey):Bool
		return (!active || !blockKeyboard) && FlxG.keys.checkStatus(key, JUST_RELEASED) || (active && keys.justReleased(key));
	public static function checkStatus(key:FlxKey, status:FlxInputState):Bool
	{
		return switch(status)
		{
			case JUST_PRESSED: justPressed(key);
			case PRESSED: pressed(key);
			case JUST_RELEASED: justReleased(key);
			case RELEASED: !pressed(key);
		};
	}
	public static function backPressed():Bool
	{
		#if android
		return active && !ignoreBack && !blockKeyboard && FlxG.android.justReleased.BACK;
		#else
		return false;
		#end
	}
	public static function reset()
	{
		active = false;
		keys.clear();
		ignoreBack = false;
		blockKeyboard = false;
		#if mobile
		touch = null;
		touchActive = false;
		#end
		EditorPointer.reset();
	}
}
