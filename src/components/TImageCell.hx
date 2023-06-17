package components;

#if sys
import sys.FileSystem;
#end
#if openfl
import openfl.display.BitmapData;
#end
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

	public function new() {
		super();
		image.scaleMode = "fitinside";
		image.height = 40;
	}

	// Enumeration 	the integer index of the selected value 	0 (first value)
	public function clickCell() {
		_isOpen = true;
		haxe.ui.containers.dialogs.Dialogs.openFile(function(b, files) {
			if (b == haxe.ui.containers.dialogs.Dialog.DialogButton.OK) {
				image.value = files[0].fullPath;
				validateCell();
				haxe.ui.Toolkit.callLater(function() {
					_isOpen = false;
				});
				//Main.mainView.save();
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

	public function saveCell(lineIndex:Int, previousValue:Dynamic) {
		var sheet = findAncestor(SheetView).sheet;

		var col = SheetUtils.getColumnForName(sheet, id);

		var path:String = image.resource;
		#if sys
		var md5 = ""; // haxe.crypto.Md5.make(bytes).toHex();
		var data = "";
		var obj = findAncestor(SheetView).objectToSave(lineIndex);


		
		

		var imageBank = Main.mainView.imageBank;

		if (imageBank == null)
			imageBank = {};
		if (!Reflect.hasField(imageBank, md5)) {
			if (Path.extension(path)=="svg") {
				var svg = sys.io.File.getContent(StringTools.replace(path, "file://", ""));
				md5 = haxe.crypto.Md5.encode(svg);
				data = "data:image/"
				+ Path.extension(path)
				+ ";text,"
				+ svg;
				
			}
			else {
				var bytes = sys.io.File.getBytes(StringTools.replace(path, "file://", ""));
				md5 = haxe.crypto.Md5.make(bytes).toHex();
				data = "data:image/"
				+ Path.extension(path)
				+ ";base64,"
				+ new haxe.crypto.BaseCode(haxe.io.Bytes.ofString("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")).encodeBytes(bytes)
					.toString();
				
			}
			
			Reflect.setField(imageBank, md5, data);

			var col  = SheetUtils.getColumnForName(sheet, id);  
			sheet.updateValue(col, lineIndex, previousValue);
			Main.mainView.history2.push(MainView.HistoryElement2.ChangedField(sheet,id, lineIndex,previousValue, value));
			Main.mainView.historyBox.updateHistory();
		}

		if (path == "") {
			Reflect.deleteField(obj, id);
		} else {
			Reflect.setField(obj, id, md5);
		}

		Main.mainView.imageBank = imageBank;

		value = md5;

		#end
		Main.mainView.saveImages();
		Main.mainView.save();
	}

	public override function set_value(value:Dynamic):Dynamic {
		trace(value);
		//trace(Main.mainView.imageBank );
        var imageData = Main.mainView.getImageData(value);
		if (imageData == null) {
			#if sys
			if (FileSystem.exists(value)) {
				image.resource =  "file://" + value;
			return super.set_value(value);
			}
			#end
			return super.set_value(value);
			
		}
		var iindex = imageData.indexOf(";");
		trace(imageData);
		var extension = imageData.substring(11, iindex);
		var jindex = imageData.indexOf(",", iindex);
		var type = imageData.substring(iindex+1, jindex );
		var content = imageData.substring(jindex+1);
		#if openfl
		trace(extension,type);
		//percentHeight = 100;
		height = 40;
		switch ([extension, type]) {
			case ["svg", "text"]:
				trace(type);
				trace(content);
				var svg = new format.SVG(content);
				trace(width, height,svg.data.width, svg.data.height);

				haxe.ui.Toolkit.callLater(function f(){
					trace(width, height,svg.data.width, svg.data.height);
				
				svg.render(getImageDisplay().sprite.graphics);
				});
				//image.resource = svg;

			case [_, "base64"]:
				openfl.display.BitmapData.loadFromBase64(content, extension).onComplete(function(bitmap) {
					image.resource = bitmap;
				});
			default:


		}
		
		
		#elseif heaps
		//haxe.crypto.Base64.decode(data);

		#end
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
