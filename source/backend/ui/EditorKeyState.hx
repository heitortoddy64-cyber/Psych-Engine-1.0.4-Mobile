package backend.ui;

/** Frame-based editor commands, independent of the system keyboard/IME. */
class EditorKeyState
{
	var current:Map<Int, Bool> = [];
	var previous:Map<Int, Bool> = [];
	var repeated:Map<Int, Bool> = [];
	public function new() {}
	public function beginFrame()
	{
		previous = current;
		current = [];
		repeated.clear();
	}
	public function hold(key:Int) current.set(key, true);
	public function repeat(key:Int) { hold(key); repeated.set(key, true); }
	public function pressed(key:Int):Bool return current.exists(key);
	public function justPressed(key:Int):Bool return current.exists(key) && (!previous.exists(key) || repeated.exists(key));
	public function justReleased(key:Int):Bool return previous.exists(key) && !current.exists(key);
	public function clear()
	{
		current.clear();
		previous.clear();
		repeated.clear();
	}
}
