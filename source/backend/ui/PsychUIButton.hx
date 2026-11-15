package backend.ui;

import backend.ui.PsychUIBox.UIStyleData;

class PsychUIButton extends FlxSpriteGroup
{
	public static final CLICK_EVENT = 'button_click';
	public static final PRESS_EVENT = 'button_press';

	public var name:String;
	public var label(default, set):String;
	public var bg:FlxSprite;
	public var text:FlxText;

	public var onChangeState:String->Void;
	public var onClick:Void->Void;
	
	public var clickStyle:UIStyleData = {
		bgColor: FlxColor.BLACK,
		textColor: FlxColor.WHITE,
		bgAlpha: 1
	};
	public var hoverStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};
	public var normalStyle:UIStyleData = {
		bgColor: 0xFFAAAAAA,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};

	public function new(x:Float = 0, y:Float = 0, label:String = '', ?onClick:Void->Void = null, ?wid:Int = 80, ?hei:Int = 20)
	{
		super(x, y);
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(bg);
		bg.color = 0xFFAAAAAA;
		bg.alpha = 0.6;

		text = new FlxText(0, 0, 1, '');
		text.alignment = CENTER;
		add(text);
		resize(wid, hei);
		this.label = label;
		
		this.onClick = onClick;
		forceCheckNext = true;
	}

	public var isClicked:Bool = false;
	public var forceCheckNext:Bool = false;
	public var broadcastButtonEvent:Bool = true;
	var _firstFrame:Bool = true;
	var touchX:Float = 0;
	var touchY:Float = 0;
	function click()
	{
		if(onClick != null) onClick();
		if(broadcastButtonEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(_firstFrame)
		{
			bg.color = normalStyle.bgColor;
			bg.alpha = normalStyle.bgAlpha;
			text.color = normalStyle.textColor;
			_firstFrame = false;
		}
		
		if(isClicked && EditorPointer.released)
		{
			if(EditorPointer.touchActive && EditorPointer.justReleased && EditorPointer.overlaps(bg, camera)
				&& Math.abs(EditorPointer.screenX-touchX)<18 && Math.abs(EditorPointer.screenY-touchY)<18) click();
			forceCheckNext = true;
			isClicked = false;
		}

		if(forceCheckNext || EditorPointer.justMoved || EditorPointer.justPressed)
		{
			var overlapped:Bool = (EditorPointer.overlaps(bg, camera));

			forceCheckNext = false;

			if(!isClicked)
			{
				var style:UIStyleData = (overlapped) ? hoverStyle : normalStyle;
				bg.color = style.bgColor;
				bg.alpha = style.bgAlpha;
				text.color = style.textColor;
			}

			if(overlapped && EditorPointer.justPressed)
			{
				touchX=EditorPointer.screenX; touchY=EditorPointer.screenY;
				isClicked = true;
				bg.color = clickStyle.bgColor;
				bg.alpha = clickStyle.bgAlpha;
				text.color = clickStyle.textColor;
				// Consume the initial touch without executing the release-only action.
				if(EditorPointer.touchActive && broadcastButtonEvent) PsychUIEventHandler.event(PRESS_EVENT, this);
				if(!EditorPointer.touchActive) click();
			}
		}
	}

	public function resize(width:Int, height:Int)
	{
		bg.setGraphicSize(width, height);
		bg.updateHitbox();
		text.fieldWidth = width;
		text.x = bg.x;
		text.y = bg.y + height/2 - text.height/2;
	}

	function set_label(v:String)
	{
		if(text != null && text.exists) text.text = v;
		return (label = v);
	}
}
