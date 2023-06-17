package components;

import haxe.ui.components.Image;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Image;

@:xml('
<interactivecomponent>
<image id="image" />
</interactivecomponent>
')
class TTileCell extends InteractiveComponent implements ICell implements IClickableCell {
    private var _isOpen = false;

    public function clickCell() {
        _isOpen = true;
		var dia = new dialogs.TileDialog();
        dia.show();
    }

    public function closeCell() {
	}

    public function isOpen() {
		return _isOpen;
	}

    public function validateCell(focusNext:Bool = true) {
		dispatch(new UIEvent(UIEvent.CHANGE));

		var sheet = findAncestor(SheetView);
		haxe.ui.Toolkit.callLater(function f() {
			if (focusNext)
				sheet.cursor.focusNext();
		});
	}

    public function saveCell(lineIndex:Int, previousValue:Dynamic) {
		var sheet = findAncestor(SheetView).sheet;

		var col = SheetUtils.getColumnForName(sheet, id);

		var path:String = image.resource;

		var col  = SheetUtils.getColumnForName(sheet, id);  
        sheet.updateValue(col, lineIndex, previousValue);
        Main.mainView.history2.push(MainView.HistoryElement2.ChangedField(sheet,id, lineIndex,previousValue, value));
        Main.mainView.historyBox.updateHistory();
        /*
		#if sys
		var bytes = sys.io.File.getBytes(StringTools.replace(path, "file://", ""));
		var md5 = haxe.crypto.Md5.make(bytes).toHex();

		if (path == "") {
			Reflect.deleteField(sheet.lines[lineIndex], id);
		} else {
			Reflect.setField(sheet.lines[lineIndex], id, md5);
		}
		

		var imageBank = Main.mainView.imageBank;

		if (imageBank == null)
			imageBank = {};
		if (!Reflect.hasField(imageBank, md5)) {
			var data = "data:image/"
				+ Path.extension(path)
				+ ";base64,"
				+ new haxe.crypto.BaseCode(haxe.io.Bytes.ofString("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")).encodeBytes(bytes)
					.toString();
			trace(data.substr(0, 40));
			Reflect.setField(imageBank, md5, data);
		}

		Main.mainView.imageBank = imageBank;

		value = md5;

		#end*/
	}

}