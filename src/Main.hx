package;

import components.SheetView;
import haxe.ui.core.Screen;
import haxe.ui.HaxeUIApp;
import haxe.ui.focus.FocusManager;
import haxe.ui.core.ItemRenderer;
import haxe.ui.core.Component;
import components.ICell;
import components.IClickableCell;

@:access(FocusManager)
class Main {
	public static var mainView:MainView = null;

	public static function main() {
		var app = new HaxeUIApp();
		app.ready(function() {
			mainView = new MainView();
			app.addComponent(mainView);
			#if heaps
			
			Screen.instance.registerEvent(haxe.ui.events.KeyboardEvent.KEY_PRESS, shortcutKey, -9999);
			#else
			Screen.instance.registerEvent(haxe.ui.events.KeyboardEvent.KEY_DOWN, shortcutKey);
			Screen.instance.registerEvent(haxe.ui.events.KeyboardEvent.KEY_UP, upKey);
			#end

			app.start();
		});
	}

	public static var downKey:Int =0;

	static function upKey(e) {
		downKey = 0;
	}

	static function shortcutKey(e:haxe.ui.events.KeyboardEvent) {
		trace(e);
		var isKeyPressedContinuously:Bool = false;
		if (downKey == 0) {
			downKey = e.keyCode;
		}
		else {
			isKeyPressedContinuously = true;
			
		}
		
		
		var sheetView = mainView.shownSheetView();
		if (!mainView.sideview.hidden) {
			// if sideview has a sheet/list opened
			if (mainView.sideview.findComponents(components.SheetView).length > 0) {
				sheetView = mainView.sideview.findComponents(components.SheetView)[0];
			}
		}
		if (sheetView == null)
			return;
		var r = sheetView.cursor.rendererForCursor();
		var ccell:IClickableCell = null;
		if (r != null) {
			trace(r);
			var cell = r.getComponentAt(0);
			ccell = if ((cell is IClickableCell)) {
				cast cell;
			} else {
				null;
			}
		}

		// First key events that accept multiple key downs
		switch ([e.ctrlKey, e.keyCode, ccell == null]) {
			case [false, 37, true]: // Left
				sheetView.cursor.moveLeft();
			case [false, 37, false] if (!ccell.isOpen()): // Left
				sheetView.cursor.moveLeft();
			case [false, 38, true]: // UP
				sheetView.cursor.moveUp();
			case [false, 38, false] if (!ccell.isOpen()):
				sheetView.cursor.moveUp();
			case [false, 39, true]: // Right
				sheetView.cursor.moveRight();
			case [false, 39, false] if (!ccell.isOpen()): // Right
				sheetView.cursor.moveRight();
			case [false, 40, true]: // DOWN
				sheetView.cursor.moveDown();
			case [false, 40, false] if (!ccell.isOpen()): // DOWN
				sheetView.cursor.moveDown();
			default:
		}


		if (isKeyPressedContinuously) return;
		switch ([e.ctrlKey, e.keyCode, ccell == null]) {
			case [true, 84, _]: // T
				mainView.newSheet(e);
			case [true, 69, _]: // E
				mainView.newColumn(e);
			case [true, 67, _]: // C
				sheetView.copy();
			case [true, 88, _]: // X
				sheetView.cut();
			case [true, 86, _]: // V
				sheetView.paste(mainView.clipboard);
			case [true, 90, _]: // Z
				trace("undo");
				mainView.undo();
			case [false, 46, _] if (!ccell.isOpen()): // del
				sheetView.delete();
			
			case [false, 45, _]: // INS
				sheetView.insertLine(sheetView.cursor.y);
			case [false, 96|97|98|99|100|101|102|103, false]: // numbers
				if (ccell.isOpen() && ((ccell is components.TFlagsCell))) {
					var flags = cast (ccell, components.TFlagsCell);
					flags.pressKeyCode(e.keyCode);
				}
			case [false, 27,  _]:
				if (!mainView.sideview.hidden) {
					if ((ccell == null) || !ccell.isOpen()) {
						mainView.sideview.hide();
						Main.mainView.sideview.removeAllComponents();
					}	
				}
				else if (ccell !=  null && ccell.isOpen()) {
					ccell.closeCell();
				}
			case [false, 32, false]: // Space
				if (!ccell.isOpen()) {
					ccell.clickCell();
					e.cancel();
				}
			case [false, 13, false]: // Enter
				// haxe.ui.Toolkit.callLater(function f() {
				if (!ccell.isOpen()) {
					ccell.clickCell();
					e.cancel();
				} else {
					ccell.validateCell();
					e.cancel();
				}
			//  });
			case _:
		}

		if (e.canceled)
			return;
	}

	/*
			case 'V'.code if( ctrlDown ):
			if( cursor.s == null || clipboard == null || js.node.webkit.Clipboard.getInstance().get("text")  != clipboard.text )
				return;
			var sheet = cursor.s;
			var posX = cursor.x < 0 ? 0 : cursor.x;
			var posY = cursor.y < 0 ? 0 : cursor.y;
			for( obj1 in clipboard.data ) {
				if( posY == sheet.lines.length )
					sheet.newLine();
				var obj2 = sheet.lines[posY];
				for( cid in 0...clipboard.schema.length ) {
					var c1 = clipboard.schema[cid];
					var c2 = sheet.columns[cid + posX];
					if( c2 == null ) continue;
					var f = base.getConvFunction(c1.type, c2.type);
					var v : Dynamic = Reflect.field(obj1, c1.name);
					if( f == null )
						v = base.getDefault(c2);
					else {
						// make a deep copy to erase references
						if( v != null ) v = haxe.Json.parse(haxe.Json.stringify(v));
						if( f.f != null )
							v = f.f(v);
					}
					if( v == null && !c2.opt )
						v = base.getDefault(c2);
					if( v == null )
						Reflect.deleteField(obj2, c2.name);
					else
						Reflect.setField(obj2, c2.name, v);
				}
				posY++;
			}
			sheet.sync();
			refresh();
			save();*/
}
