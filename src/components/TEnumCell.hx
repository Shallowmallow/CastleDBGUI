package components;

import haxe.ui.components.DropDown;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;


/**
	Enumeration
	the integer index of the selected value 	0 (first value)
**/
class TEnumCell extends DropDown  implements ICell implements IClickableCell {	

	public function new() {
		super();
		onChange = function(e) {
			validateCell(false);
		}
		allowFocus = false;
	}

	public function saveCell(lineIndex:Int) {
        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id);  

		trace(selectedIndex);
        if (selectedIndex < 0) {
            Reflect.deleteField(sheet.lines[lineIndex], id);
        }
        else {
            Reflect.setField(sheet.lines[lineIndex], id, selectedIndex);
        }
		SheetUtils.changed(sheet,col,lineIndex, selectedIndex);
    }

	public override function set_value(value:Dynamic):Dynamic {
        var sheet = findAncestor(SheetView).sheet;
        var render = findAncestor(ItemRenderer);
        var index = cast (render.parentComponent,ItemRenderer).itemIndex;

		var item = dataSource.get(value);
		return super.set_value(item);
    }

	public function clickCell() {
		//allowFocus= true;
		haxe.ui.Toolkit.callLater(function f(){
        showDropDown();});
    }

	public function isOpen() {
        return dropDownOpen;
    }

	public function validateCell(focusNext:Bool = true) {		
		haxe.ui.Toolkit.callLater(function f() {
			hideDropDown();
		});
		focus = false;
		allowFocus = false;
        var sheet = findAncestor(SheetView);
        haxe.ui.Toolkit.callLater(function f() {
            if (focusNext) sheet.cursor.focusNext();
        });
    }

	public function closeCell() {
        hideDropDown();
    }




}

/*		case TEnum(values):
			v.empty();
			var s = J("<select>");
			v.addClass("edit");
			for( i in 0...values.length )
				J("<option>").attr("value", "" + i).attr(val == i ? "selected" : "_sel", "selected").text(values[i]).appendTo(s);
			if( c.opt )
				J("<option>").attr("value","-1").text("--- None ---").prependTo(s);
			v.append(s);
			s.change(function(e) {
				val = Std.parseInt(s.val());
				if( val < 0 ) {
					val = null;
					Reflect.deleteField(obj, c.name);
				} else
					Reflect.setField(obj, c.name, val);
				html = getValue();
				changed();
				editDone();
				e.stopPropagation();
			});
			s.keydown(function(e) {
				switch( e.keyCode ) {
				case K.LEFT, K.RIGHT:
					s.blur();
					return;
				case K.TAB:
					s.blur();
					moveCursor(e.shiftKey? -1:1, 0, false, false);
					haxe.Timer.delay(function() J(".cursor").dblclick(), 1);
					e.preventDefault();
				default:
				}
				e.stopPropagation();
			});
			s.blur(function(_) {
				editDone();
			});
			s.focus();
			var event : Dynamic = cast js.Browser.document.createEvent('MouseEvents');
			event.initMouseEvent('mousedown', true, true, js.Browser.window);
			s[0].dispatchEvent(event);
            */