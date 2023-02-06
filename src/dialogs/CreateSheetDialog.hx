package dialogs;

import haxe.ui.components.Button;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Component;
import cdb.Sheet;
import haxe.ui.containers.Form;

@xml('
<vbox>

<label text="Sheet Props" />
<hbox> 
<label text="Sheet Name" />
<textfield id="sheet_name" text="" />
</hbox>

<checkbox id="level" text="Create Level"/>

</vbox>
<!--dialog>
<!--form id="form" columns="2">
<label text="Sheet Name" />
<textfield id="sheet_name" text="" />
<checkbox id="level" text="Create Level"/>

</form>
</dialog-->
')
class CreateSheetDialog extends Dialog {
	public function new() {
		super();

		buttons = DialogButton.CANCEL | "Create";
		defaultButton = "Create";

		sheet_name.registerEvent(UIEvent.SUBMIT, function(e) {trace("entered");this.dispatch(e);});

		onDialogClosed = function(e:DialogEvent) {
			
			trace(e.button);
			if (e.button == "Create") {
				if (!Main.mainView.base.r_ident.match(StringTools.trim(sheet_name.text))){
					SheetUtils.error('Invalid Sheet Name');
					e.cancel();
				}

				var sheet = SheetUtils.createSheet(sheet_name.text, level.selected);

				Main.mainView.prefs.curSheet = Main.mainView.base.sheets.length - 1;
				sheet.sync();
				Main.mainView.save();


				if (sheet != null) {
					Main.mainView.new_column.disabled = false;
					if (level.selected) {
						Main.mainView.new_line.disabled = false;
					}


					var sheetView = createSheetView(sheet);
                    
					Main.mainView.tabs.addComponent(sheetView);
					Main.mainView.tabs.selectedPage = sheetView;
					for (b in Main.mainView.tabs.findComponents("tabbarbutton", Button)) {
						b.allowFocus = false;
					}

					sheetView.registerEvent(UIEvent.READY, function(e) {  // Or it will bug incase there is already some data in the sheet
						sheetView.refresh();
					});

				} else {
					e.cancel();
				}
			}
		}
	}

	function createSheetView(s:Sheet) {
		var sheetView = new components.SheetView();
		sheetView.text = sheet_name.text;
		sheetView.sheet = s;
		haxe.ui.Toolkit.callLater(function f() {
			for (c in Main.mainView.tabs.findComponents("tabbar-button", Component)) {
				c.onRightClick = function(event) {
					var menu = new popups.SheetPopup(sheetView);
					menu.left = event.screenX;
					menu.top = event.screenY;
					menu.show();
				}
			}
		});

		return sheetView;
	}
	
}

@:xml('
    <form>
		<label text="Sheet Name" />
		<textfield id="sheet_name" text="" />
		<checkbox id="level" text="Create Level"/>	
    </form>
')
class MyForm extends Form {
    public override function validateForm(fn:Bool -> Void) {
        var invalidFields = [];
        if (sheet_name.text == "") {
            invalidFields.push(sheet_name);
        }
		if (!Main.mainView.base.r_ident.match(StringTools.trim(sheet_name.text))){
			invalidFields.push(sheet_name);
			SheetUtils.error('Invalid Sheet Name');
		}
		/*
        for (f in invalidFields) {
            //f.shake().flash();
        }*/
        fn(invalidFields.length == 0);
    }
}
/**

	/*
		function createSheet( name : String, level : Bool ) {
			name = StringTools.trim(name);
			if( !base.r_ident.match(name) ) {
				error("Invalid sheet name");
				return;
			}
			var s = base.createSheet(name);
			if( s == null ) {
				error("Sheet name already in use");
				return;
			}
			J("#newsheet").hide();
			prefs.curSheet = base.sheets.length - 1;
			s.sync();
			if( level ) initLevel(s);
			initContent();
			save();
	}
**/
