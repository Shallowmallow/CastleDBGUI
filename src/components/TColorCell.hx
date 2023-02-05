package components;

import haxe.ui.core.Component;
import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;

/**
    Color
    A numerical value that represents an RGB color. 

    Color 	the color value as integer 	0 (black)
**/
class TColorCell extends ColorPickerPopup implements ICell implements  IClickableCell {

    public function new() {
        super();
        allowFocus = false;
        liveTracking = true;
    }

    public function saveCell(lineIndex:Int) {
        var sheet = findAncestor(SheetView).sheet;
        Reflect.setField(sheet.lines[lineIndex], id, selectedItem);
    }

    public function clickCell() {
        showDropDown();
    }
    public function closeCell() {
        hideDropDown();
    }

    public function validateCell(focusNext:Bool = true) {
        dispatch(new UIEvent(UIEvent.CHANGE));
        var sheet = findAncestor(SheetView);
        haxe.ui.Toolkit.callLater(function f() {
            if (focusNext) sheet.cursor.focusNext();
        });
    }

    public function isOpen() {
        return dropDownOpen;
    }
}

/*					var id = Std.random(0x1);
			v.html('<div class="modal" onclick="$(\'#_c${id}\').spectrum(\'toggle\')"></div><input type="text" id="_c${id}"/>');
			var spect : Dynamic = J('#_c$id');
			spect.spectrum( { color : "#" + StringTools.hex(val, 6), showInput: true, showButtons: false, change : function() spect.spectrum('hide'), hide : function(vcol:Dynamic) {
				var color = Std.parseInt("0x" + vcol.toHex());
				val = color;
				Reflect.setField(obj, c.name, color);
				v.html(getValue());
				save();
			}}).spectrum("show");
            */