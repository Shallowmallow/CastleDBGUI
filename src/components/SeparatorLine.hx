package components;

import haxe.ui.core.InteractiveComponent;
import haxe.ui.components.Label;
import cdb.Data.Separator;
import haxe.ui.core.ItemRenderer;
import haxe.ui.events.UIEvent;

@:xml('
<interactivecomponent>
<label id="label"/>
<textfield id="textfield" hidden="true" width="100%" verticalAlign="center"/>
</interactivecomponent>
')
class SeparatorLine extends InteractiveComponent implements IClickableCell {

    public var separator:Separator;


    public override function set_value(value:Dynamic):Dynamic {

        trace(value);

        separator = value;
        if (value == null) {
            this.hide();
            return value;
        }

        height = 30;
        this.show();
        this.parentComponent.show();

        label.text = separator.title;

        if (separator.title == null) label.text= "no title";
        trace(label.text);

        var render = findAncestor(ItemRenderer).parentComponent;
        for (c in render.childComponents ) {
            trace(c.id);
            if (c.findComponent(SeparatorLine) == null) {
                trace(c.childComponents[0].id);
                c.hide();
                c.childComponents[0].hide();

            }
        }

        //if ((Type.typeof(value) == Separator)) {
          //  var sep = cast(value, Separator);
           // text = sep.title;
        //}
/*

        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id);
        var render = findAncestor(ItemRenderer);
        var index = cast (render.parentComponent,ItemRenderer).itemIndex;*/
        //TODO
        return value;
    }

    public function clickCell() {
		label.hide();
		textfield.text = separator.title;
		allowFocus = true; // Why ??? Needed to work
		haxe.ui.Toolkit.callLater(function f() {
            textfield.show();
            textfield.focus = false;
			textfield.focus = true;
		});
	}

    public function closeCell() {
        label.show();
        textfield.hide();
    }

    public function isOpen() {
		return !textfield.hidden;
	}

    public function validateCell(focusNext:Bool = true) {
		label.show();
		label.text = textfield.text;
        separator.title = textfield.text;
		value = separator;
		dispatch(new UIEvent(UIEvent.CHANGE));
		var sheet = findAncestor(SheetView);
		haxe.ui.Toolkit.callLater(function f() {
			if (focusNext)
				sheet.cursor.focusNext();
			textfield.hide();
		});
	}
}



/*typedef Separator = {
	var ?index : Int;
	var ?id : String;
	var ?title : String;
	var ?level : Int;
	var ?path : String;
}*/