package components;

import haxe.ui.focus.IFocusable;
import haxe.ui.Toolkit;
import haxe.ui.components.DropDown;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.core.ItemRenderer;

class TFlagsCell extends DropDown implements ICell implements IClickableCell {

    @:clonable public var flags:Array<String>;
    //@:clonable @:value(bitValue)                                public var value:Dynamic;

    public var bitValue = 0;

    public var firstSave = false;

    public function new(a:Array<String>){
        super();
        DropDownBuilder.HANDLER_MAP.set("myDropDownHandler", Type.getClassName(MyDropDownHandler));
        type = "myDropDownHandler";
        text = "no flags";

            allowFocus = false;
            disableInteractivity(true);
    }

    public function setFlags(a:Array<String>) {
        var builder:DropDownBuilder = cast(_compositeBuilder, DropDownBuilder);
        var handler = cast(builder.handler, MyDropDownHandler);
        handler.setFlags(a);
    }

    public function saveCell(lineIndex:Int, previousValue:Dynamic) {

        var sheet = findAncestor(SheetView).sheet;
        var obj = findAncestor(SheetView).objectToSave(lineIndex);

        var col  = SheetUtils.getColumnForName(sheet, id);  
        

        if (col.opt && (bitValue == 0)) {
            Reflect.deleteField(obj, id);
        }
        else {
            Reflect.setField(obj, id, bitValue);
        }

        var col  = SheetUtils.getColumnForName(sheet, id);  
        sheet.updateValue(col, lineIndex, previousValue);
        Main.mainView.history2.push(MainView.HistoryElement2.ChangedField(sheet,id, lineIndex,previousValue, value));
        Main.mainView.historyBox.updateHistory();
    }

    public override function onReady() {
        super.onReady();
        setFlags(flags);
    }

    public function clickCell() {
        showDropDown();
    }

    public function pressKeyCode(keyCode:Int) {
        var builder:DropDownBuilder = cast(_compositeBuilder, DropDownBuilder);
        var handler = cast(builder.handler, MyDropDownHandler);


        var bitPosition = keyCode - 96;
        
        if (bitPosition >= handler.checkBoxes().length) return;
        handler.checkBoxes()[bitPosition].selected = !handler.checkBoxes()[bitPosition] .selected;
    }

    public function closeCell() {
        hideDropDown();
    }

    
    public override function set_value(value:Dynamic):Dynamic {
        if ((value is Int) == false) return this.value;

        if (value == 0) text = "no flags";
        var builder:DropDownBuilder = cast(_compositeBuilder, DropDownBuilder);
        var handler = cast(builder.handler, MyDropDownHandler);
        handler.setFlagsBit(value);

        return super.set_value(value);
    }

    public function isOpen() {
        return dropDownOpen;
    }

    public function validateCell(focusNext:Bool = true) {		
        dispatch(new UIEvent(UIEvent.CHANGE));
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

}

@:xml('

<vbox style="padding:10px;spacing:10px;">
    <hbox style="spacing:10px;">
        <grid id="grid">

        </grid>
    </hbox>
</vbox>')
class MyDropDownHandlerView extends VBox {
    public function new() {
        super();
    }

    public function setFlags(a:Array<String>) {
        var i = 0;
        for ( s in a) {
            var checkBox = new haxe.ui.components.CheckBox();
            checkBox.text = '($i)' +s;
            checkBox.userData = s;
            checkBox.allowFocus = false;
            checkBox.findComponent(CheckBoxValue).allowFocus = false;
            i++;
            
            grid.addComponent(checkBox);
        }
    }

    
}

@:access(haxe.ui.core.Component)
class MyDropDownHandler extends DropDownHandler {
    private var _view:MyDropDownHandlerView = null;
    
    private override function get_component():Component {
        if (_view == null) {
            _view = new MyDropDownHandlerView();
        }
        return _view;
    }

    public function checkBoxes() {
        return _view.grid.findComponents(CheckBox);
    }

    public function setFlags(a:Array<String>) {
        var view = cast(component, MyDropDownHandlerView);
        view.setFlags(a);
        for (c in _view.grid.findComponents(CheckBox)) {
            c.onChange = function(e) {
                updateText();
            }
        }
    }

    public function setFlagsBit(value:Int) {
        var view = cast (component, MyDropDownHandlerView);
        var checkboxes = view.grid.findComponents(CheckBox);
        if (checkboxes.length <=0) return;
        //trace(value.length);

        var val = value ;
        /*
        for( i in 0...value.length ) {
            val & (1 << i) != 0;

        }*/
        var i = 0;
        
        for (c in view.grid.findComponents(CheckBox)) {
            trace(val & (1 << i));
            c.selected = (val & (1 << i) != 0);
            i++;
        }
        updateText();
    }

    function updateText() {
        var items = [];
        var i = 0;
        var val = 0;
        for (c in _view.grid.findComponents(CheckBox)) {
            val &= ~(1 << i);
            if (c.selected) {
                items.push(c.userData);

                val |= 1 << i;
            }
            i++;
        }
        cast(_dropdown, TFlagsCell).bitValue = val;
        _dropdown.text = items.join(", ");
        _dropdown.dispatch(new UIEvent(UIEvent.CHANGE));
    }
}

/*case TFlags(values):
			var div = J("<div>").addClass("flagValues");
			div.click(function(e) e.stopPropagation()).dblclick(function(e) e.stopPropagation());
			for( i in 0...values.length ) {
				var f = J("<input>").attr("type", "checkbox").prop("checked", val & (1 << i) != 0).change(function(e) {
					val &= ~(1 << i);
					if( JTHIS.prop("checked") ) val |= 1 << i;
					e.stopPropagation();
				});
				J("<label>").text(values[i]).appendTo(div).append(f);
			}
			v.empty();
			v.append(div);
			cursor.onchange = function() {
				if( c.opt && val == 0 ) {
					val = null;
					Reflect.deleteField(obj, c.name);
				} else
					Reflect.setField(obj, c.name, val);
				html = getValue();
				editDone();
				save();
			};

            */