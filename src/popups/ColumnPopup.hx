package popups;

import dialogs.CreateColumnDialog;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.Menu;
import components.SheetView;

@:xml('
<menu>
    <menuitem id="nedit" text="Edit"/>
    <menuitem id="nins" text="Add Column"/>
    <menuitem id="nleft" text="Move Left"/>
    <menuitem id="nright" text="Move Right"/>
    <menuitem id="ndel" text="Delete"/>
    <menucheckbox id="ndisp" text="Display Column"/>
    <menucheckbox id="nicon" text="Display Icon"/>
</menu>
')
class ColumnPopup extends Menu {
	public function new(sheetView:SheetView, cdbCol:cdb.Data.Column, ?isProperties:Bool) {
		super();

		ndisp.disabled = true;
		nicon.disabled = true;

		var c = cdbCol;
		if (c== null) return;


		var sheet = sheetView.sheet;
		
		ndisp.selected = sheet.props.displayColumn == c.name;
		nicon.selected = sheet.props.displayIcon == c.name;
		
		switch (c.type) {
			case TString, TRef(_):
				ndisp.disabled = false;
			case TTilePos:
				nicon.disabled = false;
			default:
		}

		switch (cdbCol.type) {
			case TId, TString, TEnum(_), TFlags(_):
				var conv = new Menu();
				conv.text = "Convert";
				for (k in [
					{n: "lowercase", f: function(s:String) return s.toLowerCase()},
					{n: "UPPERCASE", f: function(s:String) return s.toUpperCase()},
					{n: "UpperIdent", f: function(s:String) return s.substr(0, 1).toUpperCase() + s.substr(1)},
					{n: "lowerIdent", f: function(s:String) return s.substr(0, 1).toLowerCase() + s.substr(1)},
				]) {
					var item = new MenuItem();
					conv.addComponent(item);
					item.text = k.n;
					item.onClick = function(e) {
						var c = cdbCol;
						var sheet = sheetView.sheet;

						switch (c.type) {
							case TEnum(values), TFlags(values):
								for (i in 0...values.length)
									values[i] = k.f(values[i]);
							default:
								var refMap = new Map();
								for (obj in sheet.getLines()) {
									var t = Reflect.field(obj, c.name);
									if (t != null && t != "") {
										var t2 = k.f(t);
										if (t2 == null && !c.opt)
											t2 = "";
										if (t2 == null)
											Reflect.deleteField(obj, c.name);
										else {
											Reflect.setField(obj, c.name, t2);
											if (t2 != "")
												refMap.set(t, t2);
										}
									}
								}
								if (c.type == TId)
									Main.mainView.base.updateRefs(sheet, refMap);
								sheet.sync(); // might have changed ID or DISP
						}

//						sheetView.refreshData();
						Main.mainView.save();
					};
				}
				this.addComponent(conv);
			case TInt, TFloat:
				var conv = new Menu();
				conv.text = "Convert";
				for (k in [
					{n: "* 10", f: function(s:Float) return s * 10},
					{n: "/ 10", f: function(s:Float) return s / 10},
					{n: "+ 1", f: function(s:Float) return s + 1},
					{n: "- 1", f: function(s:Float) return s - 1},
				]) {
					var c = cdbCol;
					var sheet = sheetView.sheet;
					var m = new MenuItem();
					m.text = k.n;
					m.onClick = function(e) {
						for (obj in sheetView.sheet.getLines()) {
							var t = Reflect.field(obj, c.name);
							//if (t != null) {
								var t2 = k.f(t);
								if (c.type == TInt)
									t2 = Std.int(t2);
								Reflect.setField(obj, c.name, t2);
							//}
						}
//						sheetView.refreshData();
						Main.mainView.save();
					};
					conv.addComponent(m);
				}
				addComponent(conv);
			case _:
		}

		nins.onClick = function(e) {
			var dia = new CreateColumnDialog(sheetView, Lambda.indexOf(sheetView.sheet.columns, cdbCol) + 1);
			dia.show();
		};

		var sheet = sheetView.sheet;
		var c = cdbCol;

		nleft.onClick = function(e) {
			var index = Lambda.indexOf(sheet.columns, c);
			if (index > 0) {
				sheet.columns.remove(c);
				sheet.columns.insert(index - 1, c);
				sheetView.refresh();
				Main.mainView.save();
			}
		};
		nright.onClick = function(e) {
			var index = Lambda.indexOf(sheet.columns, c);
			if (index < sheet.columns.length - 1) {
				sheet.columns.remove(c);
				sheet.columns.insert(index + 1, c);
				sheetView.refresh();
				Main.mainView.save();
			}
		}

		nedit.onClick = function(e) {
				var dia = new dialogs.CreateColumnDialog(sheetView, c);
            dia.show();
		};

		ndel.onClick = function(e) {
			if (!isProperties) {
				SheetUtils.deleteColumn(sheet, c);
			} else {
				haxe.ui.containers.dialogs.Dialogs.messageBox('Do you really want to delete this property for all objects?', 'Question', 'question')
					.onDialogClosed = function(e) {
						
							if (cast e.button) {
								SheetUtils.deleteColumn(sheet, c);
						}
					}}

            sheetView.refresh();
		};

        ndisp.onClick = function(e) {
            if( sheet.props.displayColumn == c.name ) {
                sheet.props.displayColumn = null;
            } else {
                sheet.props.displayColumn = c.name;
            }
            sheet.sync();
            sheetView.refresh();
            Main.mainView.save();
        };

        nicon.onClick = function(e) {
            if( sheet.props.displayIcon == c.name ) {
                sheet.props.displayIcon = null;
            } else {
                sheet.props.displayIcon = c.name;
            }
            sheet.sync();
            sheetView.refresh();
            Main.mainView.save();
        };
    
        
	}

}
/*
	
	
 */
