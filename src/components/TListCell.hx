package components;

import haxe.ui.components.Button;
import haxe.ui.components.TabBar;
import cdb.Sheet;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.components.Label;
import haxe.ui.events.UIEvent;

@:xml('
<interactivecomponent>
<label id="label" width="100%" verticalAlign="center"/>
</interactivecomponent>')
@:access(haxe.ui.components.TabBarButton)
class TListCell extends InteractiveComponent  implements ICell implements IClickableCell {

	public var subVal:Array<Dynamic<String>> = [];

    public function new(){
        super();
		addClass("clickable_cell");
    }

    public function clickCell(){

		var sheetMain = findAncestor(SheetView).sheet;
        var col  = SheetUtils.getColumnForName(sheetMain, id); 
		var sheet = sheetMain.getSub(col);


		var sheetView = new components.SheetView();
		trace(sheet.name);
		sheetView.text = sheet.name; //"subsheet";
		sheetView.sheet = sheet;
		sheetView.id = sheet.name;
		sheetView.subVal =  subVal;

		sheetView.parentSheet = sheetMain;
//		sheetView.parentId    = id;
                    
		Main.mainView.tabs.addComponent(sheetView);
		Main.mainView.tabs.selectedPage = sheetView;
		var b =  Main.mainView.tabs.findComponent(sheetView.id+ "_button", Button);
		//Main.mainView.tabs.findComponents(Button,1).pop(); 
		trace(b.classes);
		b.addClass("closable");

		sheetView.registerEvent(UIEvent.READY, function(e) {  // Or it will bug incase there is already some data in the sheet
			sheetView.refresh();
		});
    }


    public override function set_value(value:Dynamic):Dynamic {
        trace(value);
		if (value == null) value = [];
		if (value == null) value = [];
		if (value == "null") value = [];
		if (!(value is Array)) value = [];
		//var sheet = Main.mainView.shownSheetView().sheet;

		

		/*
		var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id); 
		var ps = sheet.getSub(col); */
		subVal = value;
		trace(value);
        return value; //super.set_value(value);
    }

	public function saveCell(lineIndex:Int) {
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
		dispatch(new UIEvent(UIEvent.CHANGE));
       
        var sheet = findAncestor(SheetView);
        haxe.ui.Toolkit.callLater(function f() {
            if (focusNext) sheet.cursor.focusNext();
        });
	}

	public function isOpen() {
        return false;
    }

}

@:xml('
<dialog width="600" height="500">
</dialog>')
class SheetDialog extends Dialog {

	public var sheetView:SheetView = new SheetView();

	override public function new (s:Sheet) {
		super();
		sheetView.text = s.name;
		sheetView.sheet = s;
		addComponent(sheetView);
		sheetView.refreshRenderers();
	}

}

/*

case TList:
			var a : Array<Dynamic> = v;
			var ps = sheet.getSub(c);
			var out : Array<String> = [];
			var size = 0;
			for( v in a ) {
				var vals = [];
				for( c in ps.columns )
					switch( c.type ) {
					case TList, TProperties:
						continue;
					default:
						vals.push(valueHtml(c, Reflect.field(v, c.name), ps, v));
					}
				var v = vals.length == 1 ? vals[0] : ""+vals;
				if( size > 200 ) {
					out.push("...");
					break;
				}
				var vstr = v;
				if( v.indexOf("<") >= 0 ) {
					vstr = ~/<img src="[^"]+" style="display:none"[^>]+>/g.replace(vstr, "");
					vstr = ~/<img src="[^"]+"\/>/g.replace(vstr, "[I]");
					vstr = ~/<div id="[^>]+><\/div>/g.replace(vstr, "[D]");
				}
				size += vstr.length;
				out.push(v);
			}
			if( out.length == 0 )
				return "";
			return out.join(", ");

    */