package components;

import haxe.ui.data.ArrayDataSource;
import haxe.ui.components.DropDown;
import haxe.ui.events.UIEvent;

/**

	Reference
	A reference to another sheet row, using its unique idenfier. 
	Reference 	the string of the target's unique identifier 	"" (missing identifier)
**/
class TRefCell extends DropDown implements ICell implements IClickableCell {
	@:clonable public var sheetName(default,set):String;

    private var oldValue:Dynamic;

	public function new() {
		super();
		searchable = true;
		trace(sheetName);
		
	}

	public function set_sheetName(s:String) {
		sheetName = s;
		trace(sheetName);
		var sheet = Main.mainView.base.getSheet(sheetName);
		trace("bbbbb");
		var elts = [for (d in sheet.all) {id: d.id, icon: d.ico, text: d.disp}];
		trace("bbbbb");
		dataSource = ArrayDataSource.fromArray(elts);
		trace("bbbbb");
		

		return sheetName;
	}

	public function saveCell(lineIndex:Int) {
		var sheet = findAncestor(SheetView).sheet;

		var col = SheetUtils.getColumnForName(sheet, id);

		var obj  = findAncestor(SheetView).objectToSave(lineIndex);

		if (col.opt && value == "") {
			Reflect.deleteField(obj, id);
		} else {
			Reflect.setField(obj, id, value);
		}
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
			if (focusNext)
				sheet.cursor.focusNext();
		});
	}

	public function clickCell() {
        oldValue = value;
		var sheet = Main.mainView.base.getSheet(sheetName);
		var col = SheetUtils.getColumnForName(sheet, id);
		var elts = [for (d in sheet.all) {id: d.id, icon: d.ico, text: d.disp}];
		if (col.opt || value == null || value == "")
			elts.unshift({id: "~", icon: null, text: "--- None ---"});
		dataSource = ArrayDataSource.fromArray(elts);
		haxe.ui.Toolkit.callLater(function f() {
			showDropDown();
		});
	}

	public function closeCell() {
		value = oldValue;
		hideDropDown();
	}

	public function isOpen() {
		return dropDownOpen;
	}
}

/*
	case TRef(sname):
	var sdat = base.getSheet(sname);
	if( sdat == null ) return;
	v.empty();
	v.addClass("edit");

	var s = J("<select>");
	var elts = [for( d in sdat.all ){ id : d.id, ico : d.ico, text : d.disp }];
	if( c.opt || val == null || val == "" )
		elts.unshift( { id : "~", ico : null, text : "--- None ---" } );
	v.append(s);
	s.change(function(e) e.stopPropagation());

	var props : Dynamic = { data : elts };
	if( sdat.props.displayIcon != null ) {
		function buildElement(i) {
			var text = StringTools.htmlEscape(i.text);
			return J("<div>"+(i.ico == null ? "<div style='display:inline-block;width:16px'/>" : tileHtml(i.ico,true)) + " " + text+"</div>");
		}
		props.templateResult = props.templateSelection = buildElement;
	}
	(untyped s.select2)(props);
	(untyped s.select2)("val", val == null ? "" : val);
	(untyped s.select2)("open");

	s.change(function(e) {
		val = s.val();
		if( val == "~" ) {
			val = null;
			Reflect.deleteField(obj, c.name);
		} else
			Reflect.setField(obj, c.name, val);
		html = getValue();
		changed();
		editDone();
	});
	s.on("select2:close", function(_) editDone());
 */
