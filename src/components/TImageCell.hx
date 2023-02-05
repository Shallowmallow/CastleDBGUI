package components;

import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Image;
import haxe.ui.core.ItemRenderer;

/**
	Image
	An image to be displayed and stored in the database. 
	Image 	the string of the MD5 of the image content bytes, stored in the separate .img JSON data 	"" (missing image)
**/
@:xml('
<interactivecomponent>
<image id="image" />
</interactivecomponent>
')
class TImageCell extends InteractiveComponent implements ICell implements IClickableCell {
	private var _isOpen = false;

	// Enumeration 	the integer index of the selected value 	0 (first value)
	public function clickCell() {
		_isOpen = true;
		haxe.ui.containers.dialogs.Dialogs.openFile(function(b, files) {
			if (b == haxe.ui.containers.dialogs.Dialog.DialogButton.OK) {
				validateCell();
				haxe.ui.Toolkit.callLater(function() {
					_isOpen = false;
				});
			}
		}, {
			extensions: [{extension: "*"}],
			readContents: false
		});
	}

	public function closeCell() {
	}

	public function validateCell(focusNext:Bool = true) {
		dispatch(new UIEvent(UIEvent.CHANGE));

		var sheet = findAncestor(SheetView);
		haxe.ui.Toolkit.callLater(function f() {
			if (focusNext)
				sheet.cursor.focusNext();
		});
	}

	public function saveCell(lineIndex:Int) {
		var sheet = findAncestor(SheetView).sheet;

		var col = SheetUtils.getColumnForName(sheet, id);

		var path:String = image.resource;
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

		#end
	}

	public override function set_value(value:Dynamic):Dynamic {
        var imageData = Main.mainView.getImageData(value);
		var extension = imageData.substring(11, imageData.indexOf(";"));
		var base64 = imageData.substring(imageData.indexOf(";")+8);
		openfl.display.BitmapData.loadFromBase64(base64, extension).onComplete(function(bitmap) {
			image.resource = bitmap;
		});
        return super.set_value(value);
    }

	public function isOpen() {
		return _isOpen;
	}
}

/*	case TImage:
	inline function loadImage(file : String) {
		var ext = file.split(".").pop().toLowerCase();
		if( ext == "jpeg" ) ext = "jpg";
		if( ext != "png" && ext != "gif" && ext != "jpg" ) {
			error("Unsupported image extension " + ext);
			return;
		}
		var bytes = sys.io.File.getBytes(file);
		var md5 = haxe.crypto.Md5.make(bytes).toHex();
		if( imageBank == null ) imageBank = { };
		if( !Reflect.hasField(imageBank, md5) ) {
			var data = "data:image/" + ext + ";base64," + new haxe.crypto.BaseCode(haxe.io.Bytes.ofString("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")).encodeBytes(bytes).toString();
			Reflect.setField(imageBank, md5, data);
		}
		val = md5;
		Reflect.setField(obj, c.name, val);
		v.html(getValue());
		changed();
	}
	if ( untyped v.dropFile != null ) {
		loadImage(untyped v.dropFile);
	} else {
		var i = J("<input>").attr("type", "file").css("display","none").change(function(e) {
			var j = JTHIS;
			loadImage(j.val());
			j.remove();
		});
		i.appendTo(J("body"));
		i.click();
	}
 */
