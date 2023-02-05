package components;

import haxe.ui.core.InteractiveComponent;
import haxe.ui.core.ItemRenderer;
import haxe.ui.components.CheckBox;
import haxe.ui.events.UIEvent;
/**
	Boolean
    A checkbox can be used to specify if the column is true or false. 
	Boolean 	true or false 	false
**/
@:xml('
<interactivecomponent>
<checkbox id="checkbox" verticalAlign="center"/>
</interactivecomponent>
')
class TBoolCell extends InteractiveComponent implements ICell implements IClickableCell {

    public function new() {
        super();
        checkbox.allowFocus = false;
        checkbox.disableInteractivity(true);
    }


    public function saveCell(lineIndex:Int) {	
        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id);  

        if (col.opt && !checkbox.selected) {
            Reflect.deleteField(sheet.lines[lineIndex], id);
        }
        else {
            Reflect.setField(sheet.lines[lineIndex], id, checkbox.selected);
        }
    }

	public override function set_value(value:Dynamic):Dynamic {
        checkbox.selected = value;
        return super.set_value(value);
    }

	public function clickCell() {
        checkbox.selected = !checkbox.selected;
        dispatch(new UIEvent(UIEvent.CHANGE));
    }

    public function closeCell() {}

	public function validateCell(focusNext:Bool = true) {
        var sheet = findAncestor(SheetView);
        haxe.ui.Toolkit.callLater(function f() {
            if (focusNext) sheet.cursor.focusNext();
        });
    }

	public function isOpen() {
        return false;
    }

}
/*

var obj = sheet.lines[index];
		var val : Dynamic = Reflect.field(obj, c.name);
		var old = val;


case TBool:
			if( c.opt && val == false ) {
				val = null;
				Reflect.deleteField(obj, c.name);
			} else {
				val = !val;
				Reflect.setField(obj, c.name, val);
			}
			updateClasses(v, c, val);
			v.html(getValue());
			changed();*/