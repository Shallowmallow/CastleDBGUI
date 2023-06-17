package components;

import haxe.ui.layouts.HorizontalLayout;
import haxe.ui.layouts.Layout;
import haxe.ui.focus.FocusManager;
import haxe.ui.events.UIEvent;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.containers.Box;

/**
	TODO: have only one textfield that moves between TStringCell ? Seems more efficient


	BUG : if this is not a interactive component but hbox it crashes openfl. in ComponentImpl unmapevent (the text input thing)

	Text
	Any text can be input into this column. CastleDB currently does not allow multiline text. 
	Text 	the text String 	""
**/
@:xml('
<interactivecomponent>
    <label id="label" width="100%" verticalAlign="center"/>
    <textfield id="textfield" hidden="true" width="100%" verticalAlign="center"/>
</interactivecomponent>
')
class TStringCell extends InteractiveComponent implements ICell implements IClickableCell {
	public function new() {
		super();
		allowFocus = false;
	}

	public function saveCell(lineIndex:Int, previousValue:Dynamic) {
		var sheet = findAncestor(SheetView).sheet;

		Reflect.setField(findAncestor(SheetView).objectToSave(lineIndex), id, value);
		sheet.sync();
		Main.mainView.save();

		var col  = SheetUtils.getColumnForName(sheet, id);  
        sheet.updateValue(col, lineIndex, previousValue);
        Main.mainView.history2.push(MainView.HistoryElement2.ChangedField(sheet,id, lineIndex,previousValue, value));
        Main.mainView.historyBox.updateHistory();
	}

	public function clickCell() {
		label.hide();
		textfield.text = label.text;
		allowFocus = true; // Why ??? Needed to work
		haxe.ui.Toolkit.callLater(function f() {
            textfield.show();
			textfield.focus = false;
			textfield.focus = true;
		});
	}

	public function validateCell(focusNext:Bool = true) {
		label.show();
		label.text = textfield.text;
		value = textfield.text;
		dispatch(new UIEvent(UIEvent.CHANGE));
		var sheet = findAncestor(SheetView);
		haxe.ui.Toolkit.callLater(function f() {
			if (focusNext)
				sheet.cursor.focusNext();
			textfield.hide();
		});
	}

    public function closeCell() {
        label.show();
        textfield.hide();
    }

	public override function set_value(value:Dynamic):Dynamic {
		label.text = value;
		return super.set_value(value);
	}

	public function isOpen() {
		return !textfield.hidden;
	}
}
