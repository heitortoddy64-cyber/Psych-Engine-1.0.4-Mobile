package backend.ui;

import flixel.FlxBasic;
import flixel.input.FlxPointer;

/** A captured touch supplies the same camera-aware pointer API used by editor widgets. */
class EditorPointer
{
	public static var touchDown:Bool = false;
	public static var touchStarted:Bool = false;
	public static var touchEnded:Bool = false;
	public static var touchButton:Int = 0;
	public static var blocked:Bool = false;
	public static var dx:Float = 0;
	public static var dy:Float = 0;
	public static var scroll:Int = 0;
	public static var cancelled:Bool = false;
	static function source():FlxPointer
	{
		#if mobile
		if(EditorInput.active && EditorInput.touchActive && EditorInput.touch != null) return EditorInput.touch;
		#end
		return FlxG.mouse;
	}
	public static var touchActive(get, never):Bool;
	static function get_touchActive():Bool
	{
		#if mobile
		return EditorInput.active && EditorInput.touchActive;
		#else
		return false;
		#end
	}
	public static var x(get, never):Int;
	static function get_x():Int return source().x;
	public static var y(get, never):Int;
	static function get_y():Int return source().y;
	public static var screenX(get, never):Int;
	static function get_screenX():Int return source().screenX;
	public static var screenY(get, never):Int;
	static function get_screenY():Int return source().screenY;
	public static var visible(get, set):Bool;
	static function get_visible():Bool return FlxG.mouse.visible;
	static function set_visible(v:Bool):Bool return FlxG.mouse.visible = v;
	public static var pressed(get, never):Bool;
	static function get_pressed():Bool return !blocked && (touchActive ? touchDown && touchButton == 0 : FlxG.mouse.pressed);
	public static var released(get, never):Bool;
	static function get_released():Bool return !pressed;
	public static var justPressed(get, never):Bool;
	static function get_justPressed():Bool return !blocked && (touchActive ? touchStarted && touchButton == 0 : FlxG.mouse.justPressed);
	public static var justReleased(get, never):Bool;
	static function get_justReleased():Bool return !blocked && (touchActive ? touchEnded && touchButton == 0 : FlxG.mouse.justReleased);
	public static var pressedRight(get, never):Bool;
	static function get_pressedRight():Bool return !blocked && (touchActive ? touchDown && touchButton == 1 : FlxG.mouse.pressedRight);
	public static var releasedRight(get, never):Bool;
	static function get_releasedRight():Bool return !pressedRight;
	public static var justPressedRight(get, never):Bool;
	static function get_justPressedRight():Bool return !blocked && (touchActive ? touchStarted && touchButton == 1 : FlxG.mouse.justPressedRight);
	public static var justMoved(get, never):Bool;
	static function get_justMoved():Bool return !blocked && (touchActive ? dx != 0 || dy != 0 : FlxG.mouse.justMoved);
	public static var deltaScreenX(get, never):Int;
	static function get_deltaScreenX():Int return blocked ? 0 : touchActive ? Std.int(dx) : FlxG.mouse.deltaScreenX;
	public static var deltaScreenY(get, never):Int;
	static function get_deltaScreenY():Int return blocked ? 0 : touchActive ? Std.int(dy) : FlxG.mouse.deltaScreenY;
	public static var wheel(get, never):Int;
	static function get_wheel():Int return scroll != 0 ? scroll : (touchActive || blocked ? 0 : FlxG.mouse.wheel);
	public static function overlaps(object:FlxBasic, ?camera:FlxCamera):Bool return !blocked && source().overlaps(object, touchActive && object.cameras != null && object.cameras.length>0 ? object.cameras[0] : camera);
	public static function getScreenPosition(?camera:FlxCamera, ?point:FlxPoint):FlxPoint return source().getScreenPosition(camera, point);
	public static function getWorldPosition(?camera:FlxCamera, ?point:FlxPoint):FlxPoint return source().getWorldPosition(camera, point);
	public static function getPositionInCameraView(?camera:FlxCamera, ?point:FlxPoint):FlxPoint return source().getPositionInCameraView(camera, point);
	public static function reset()
	{
		touchDown = touchStarted = touchEnded = blocked = cancelled = false;
		dx = dy = 0;
		scroll = touchButton = 0;
	}
}
