package components;

import haxe.ui.core.InteractiveComponent;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.events.UIEvent;


/**
	File
    A relative or absolute path to a target file or image. 

	File 	the relative (if possible) or absolute path to the file 	"" (missing file)
**/
@:xml('
<interactivecomponent>
<label id="label" width="100%" verticalAlign="center"/>
</interactivecomponent>')
class TFileCell extends InteractiveComponent implements ICell implements IClickableCell {

    public function new(){
        super();
		addClass("clickable_cell");
    }

    public override function set_value(value:Dynamic):Dynamic {
		trace(value);
        label.text = value;
		if ((value == "") || (value == null)) label.text = "no file";
        return super.set_value(value);
    }

    public function clickCell(){
        haxe.ui.containers.dialogs.Dialogs.openFile(function(b, files) {
			if (b == haxe.ui.containers.dialogs.Dialog.DialogButton.OK) {
				trace(files[0]);
				value = files[0].fullPath;
				trace(value);
				validateCell(true);
			}
		}, {
			extensions: null,
			readContents: true
		});
    }

	public function saveCell(lineIndex:Int) {
		trace("saveCell");
        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id);  

        if (col.opt && value == "") {
            Reflect.deleteField(sheet.lines[lineIndex], id);
        }
        else {
            Reflect.setField(sheet.lines[lineIndex], id, value);
        } 

    }

	public function closeCell() {
    }

	public function validateCell(focusNext:Bool = true) {
		//value = numberstepper.value;
		dispatch(new UIEvent(UIEvent.CHANGE));
        //label.show();
       
        var sheet = findAncestor(SheetView);
        haxe.ui.Toolkit.callLater(function f() {
            if (focusNext) sheet.cursor.focusNext();
        });
	}

	public function isOpen() {
        return false;
    }

	

}

/*case TFile:
			v.empty();
			v.off();
			v.html(getValue());
			v.find("input").addClass("deletable").change(function(e) {
				if( Reflect.field(obj,c.name) != null ) {
					Reflect.deleteField(obj, c.name);
					v.html(getValue());
					save();
				}
			});
			v.dblclick(function(_) {
				chooseFile(function(path) {
					val = path;
					Reflect.setField(obj, c.name, path);
					v.html(getValue());
					save();
				});
			});
            */