package components;

import cdb.Data.DisplayType;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.components.NumberStepper;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;

/**
	Integer
	A integer number (which does not have fractional component). 

	Integer 	the integer value 	0
**/
@:xml('
<interactivecomponent>
    <label id="label" width="100%" verticalAlign="center"/>
    <numberstepper id="numberstepper" hidden="true" width="100%" verticalAlign="center"/>
</interactivecomponent>
')
class TIntCell extends InteractiveComponent implements ICell implements IClickableCell  {
	public function new() {
		super();
		allowFocus = false;
	}

	public function saveCell(lineIndex:Int) {
		var sheet = findAncestor(SheetView).sheet;

		Reflect.setField(sheet.lines[lineIndex], id, value);
	}

	public function clickCell() {
		numberstepper.show();
		label.hide();
		numberstepper.pos = Std.parseInt(label.text);
		allowFocus = true; // Why ??? Needed to work
		haxe.ui.Toolkit.callLater(function f() {
			numberstepper.focus = false;
			numberstepper.focus = true;
		});
	}

	public function closeCell() {
		label.show();
		numberstepper.hide();
	}

	public override function set_value(value:Dynamic):Dynamic {
		label.text = "" + value;
		var sheet = findAncestor(SheetView).sheet;
		for ( c in sheet.columns) {
			if (c.name ==id) {
				if (c.display == DisplayType.Percent) {
					label.text = "" + (Math.round(value * 10000)/100) + "%";

				}
			}
		}
		
        numberstepper.value = value;
		return super.set_value(value);
	}

	public function validateCell(focusNext:Bool = true) {
		value = numberstepper.value;
		dispatch(new UIEvent(UIEvent.CHANGE));
        label.show();
       
        var sheet = findAncestor(SheetView);
        haxe.ui.Toolkit.callLater(function f() {
            numberstepper.hide();
            if (focusNext) sheet.cursor.focusNext();
        });
	}

    public function isOpen() {
        return !numberstepper.hidden;
    }
}
