package;

import components.SheetView;
import haxe.io.Path;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import dialogs.CreateSheetDialog;
import dialogs.CreateColumnDialog;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.menus.Menu.MenuEvent;
import haxe.ui.core.Component;
import cdb.Sheet;
import cdb.Data.Column;

typedef Prefs = {
	windowPos:{x:Int, y:Int, w:Int, h:Int, max:Bool},
	curFile:String,
	curSheet:Int,
	recent:Array<String>,
}

typedef HistoryElement = {d:String, o:String};

@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
class MainView extends VBox {

	public var clipboard : {
		text : String,
		data : Array<Dynamic>,
		schema : Array<Column>,
	};

	@:bind(menubar, MenuEvent.MENU_SELECTED)
	private function onSelectMenu(e:MenuEvent) {
		switch (e.menuItem.id) {
			case "mexit":
				#if sys Sys.exit(0); #end
			case "mopen":
				haxe.ui.containers.dialogs.Dialogs.openFile(function(b, files) {
					if (b == haxe.ui.containers.dialogs.Dialog.DialogButton.OK) {
						prefs.curFile = files[0].fullPath;
						load();
					}
				}, {
					extensions: [{extension: "*"}],
					readContents: false
				});
			case "msave":
				try {
					var sdata = quickSave();
					haxe.ui.containers.dialogs.Dialogs.saveFile(function(but, saveResult, path) {
						if (but == haxe.ui.containers.dialogs.Dialog.DialogButton.OK) {
						prefs.curFile = path;
						saveWithHistory(sdata);
						}
					}, {
						name: Sys.getEnv("HOME"),
						text: sdata.d
					}, {
						extensions: [{extension: ".cdb"}],
						#if linux
						title: "new.cdb"
						#end
					});
				} catch (e) {
					trace(e);
				}

				//   public static function saveFile(callback:DialogButton->Bool->String->Void, fileInfo:FileInfo, options:SaveFileDialogOptions = null) {
		}
	}

	/*
		msave.click = function() {
			var i = J("<input>").attr("type", "file").attr("nwsaveas","new.cdb").css("display","none").change(function(e) {
				var j = JTHIS;
				prefs.curFile = j.val();
				save();
				j.remove();
			});
			i.appendTo(J("body"));
			i.click();
	};*/
	public var base:cdb.Database = new cdb.Database();

	public var prefs:Prefs;
	public var imageBank:Dynamic<String>; // Why a dynamic string and not a map ?

	var openedList:Map<String, Bool>;
	var existsCache:Map<String, {t:Float, r:Bool}>;

	var curSavedData:HistoryElement;
	var history:Array<HistoryElement> = [];
	var redo:Array<HistoryElement> = [];

	var lastSave:Float;

	public function new() {
		super();
		openedList = new Map();
		prefs = {
			windowPos: {
				x: 50,
				y: 50,
				w: 800,
				h: 600,
				max: false
			},
			curFile: null,
			curSheet: 0,
			recent: [],
		};
		existsCache = new Map();
		loadPrefs();

		var t = new haxe.Timer(1000);
		t.run = checkTime;

		#if openfl
		openfl.Lib.current.stage.window.onDropFile.add(function(path:String) {
			if (Path.extension(path) == "cdb") {
				prefs.curFile = path;
				load();
			}
		});
		#end
		//load(true); why ??
	}

	@:bind(new_sheet, MouseEvent.CLICK)
	public function newSheet(e) {
		var dia = new CreateSheetDialog();
		dia.show();
	}

	@:bind(new_column, MouseEvent.CLICK)
	public function newColumn(e) {
		var sheetView = cast(tabs.selectedPage, components.SheetView);
		var dia = new CreateColumnDialog(sheetView);
		dia.show();
	}

	@:bind(new_line, MouseEvent.CLICK)
	private function newLine(e) {
		var sheetView = cast(tabs.selectedPage, components.SheetView);
		sheetView.addLine(e);
	}

	public function shownSheetView() {
		var sheetView = cast(tabs.selectedPage, components.SheetView);
		return sheetView;
	}

	// ctrl-tab   change sheet

	/*
		@:bind(tabs, UIEvent.CHANGE)
		private function selectSheet(e) {
			var sheetView = cast tabs.selectedPage;
			var s = sheetView.sheet;
			viewSheet = s;
			pages.curPage = -1;
			cursor = sheetCursors.get(s.name);
			if( cursor == null ) {
				cursor = {
					x : 0,
					y : 0,
					s : s,
				};
				sheetCursors.set(s.name, cursor);
			}
			if( manual ) {
				if( level != null ) level.dispose();
				level = null;
			}
			prefs.curSheet = Lambda.indexOf(base.sheets, s);
			J("#sheets li").removeClass("active").filter("#sheet_" + prefs.curSheet).addClass("active");
			//if( manual ) refresh();


	}*/
	function quickExists(path) {
		var c = existsCache.get(path);
		if (c == null) {
			c = {t: -1e9, r: false};
			existsCache.set(path, c);
		}
		var t = haxe.Timer.stamp();
		if (c.t < t - 10) { // cache result for 10s
			#if sys
			c.r = sys.FileSystem.exists(path);
			#end
			c.t = t;
		}
		return c.r;
	}

	public function getImageData(key:String):String {
		return Reflect.field(imageBank, key);
	}

	public function getAbsPath(file:String) {
		return file.charAt(0) == "/"
			|| file.charAt(1) == ":" ? file : new haxe.io.Path(prefs.curFile).dir.split("\\").join("/") + "/" + file;
	}

	public inline function getSheet(name:String) {
		return base.getSheet(name);
	}

	public function saveWithHistory(quickSave:HistoryElement) {
		var sdata = quickSave;

		if ((curSavedData == null || sdata.d != curSavedData.d || sdata.o != curSavedData.o)) {
			this.history.push(curSavedData);
			this.redo = [];
			if (this.history.length > 100 || sdata.d.length * (this.history.length + this.redo.length) * 2 > 300 << 20)
				this.history.shift();
			curSavedData = sdata;
		}


	}

	public function save(history = true) {
		var sdata = quickSave();
		if (history) saveWithHistory(sdata);
		
		if (prefs.curFile == null)
			return;
		var tmp = Sys.getEnv("TMP");
		if (tmp == null)
			tmp = Sys.getEnv("TMPDIR");
		var tmpFile = tmp + "/" + prefs.curFile.split("\\").join("/").split("/").pop() + ".lock";
		try
			sys.io.File.saveContent(tmpFile, "LOCKED by CDB")
		catch (e:Dynamic) {};
		try {
			trace(sdata.d);
			sys.io.File.saveContent(prefs.curFile, sdata.d);
		} catch (e:Dynamic) {
			// retry once after EBUSY
			haxe.Timer.delay(function() {
				sys.io.File.saveContent(prefs.curFile, sdata.d);
			}, 500);
		}
		try
			sys.FileSystem.deleteFile(tmpFile)
		catch (e:Dynamic) {};
		lastSave = getFileTime();
	}

	public function saveImages() {
		if (prefs.curFile == null)
			return;
		var img = prefs.curFile.split(".");
		img.pop();
		var path = img.join(".") + ".img";
		#if sys
		if (imageBank == null)
			sys.FileSystem.deleteFile(path);
		else
			sys.io.File.saveContent(path, untyped haxe.Json.stringify(imageBank, null, "\t"));
		#end
	}

	function quickSave():HistoryElement {
		return {
			d: base.save(),
			o: haxe.Serializer.run(openedList),
		};
	}

	function quickLoad(sdata:HistoryElement) {
		base.load(sdata.d);
		openedList = haxe.Unserializer.run(sdata.o);
	}

	public function compressionEnabled() {
		return base.compress;
	}

	function error(msg) {
		#if js js.Browser.alert(msg); #end
	}

	function load(noError = false) {
		history = [];
		redo = [];
		base = new cdb.Database();
		#if sys
		try {
			base.load(sys.io.File.getContent(prefs.curFile));
			if (prefs.curSheet > base.sheets.length)
				prefs.curSheet = 0;
			else
				while (base.sheets[prefs.curSheet].props.hide)
					prefs.curSheet--;
		} catch (e:Dynamic) {
			if (!noError)
				error(Std.string(e));
			prefs.curFile = null;
			prefs.curSheet = 0;
			base = new cdb.Database();
		}
		try {
			var img = prefs.curFile.split(".");
			img.pop();
			imageBank = haxe.Json.parse(sys.io.File.getContent(img.join(".") + ".img"));
		} catch (e:Dynamic) {
			imageBank = null;
		}
		curSavedData = quickSave();
		#end

		loadSheets();
	}

	function loadSheets() {
		Main.mainView.tabs.removeAllPages();
		for (sheet in base.sheets) {
			if (sheet.props.hide)
				continue;
			var sheetView = createSheetView(sheet);
			sheetView.refresh();

			Main.mainView.tabs.addComponent(sheetView);
		}
	}

	function createSheetView(s:Sheet) {
		var sheetView = new components.SheetView();
		sheetView.text = s.name;
		sheetView.sheet = s;
		new_column.disabled = false;
		if (s.columns.length > 0)
			new_line.disabled = false;
		haxe.ui.Toolkit.callLater(function f() {
			for (c in tabs.findComponents("tabbar-button", Component)) {
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

	/*
		override function load(noError = false) {

			if( sys.FileSystem.exists(prefs.curFile+".mine") && !Resolver.resolveConflict(prefs.curFile) ) {
				error("CDB file has unresolved conflict, merge by hand before reloading.");
				return;
			}

			lastSave = getFileTime();
			super.load(noError);

			initContent();
			prefs.recent.remove(prefs.curFile);
			if( prefs.curFile != null )
				prefs.recent.unshift(prefs.curFile);
			if( prefs.recent.length > 8 ) prefs.recent.pop();
			mcompress.checked = base.compress;
	}*/
	function cleanImages() {
		if (imageBank == null)
			return;
		var used = new Map();
		for (s in base.sheets)
			for (c in s.columns) {
				switch (c.type) {
					case TImage:
						for (obj in s.getLines()) {
							var v = Reflect.field(obj, c.name);
							if (v != null)
								used.set(v, true);
						}
					default:
				}
			}
		for (f in Reflect.fields(imageBank))
			if (!used.get(f))
				Reflect.deleteField(imageBank, f);
	}

	function loadPrefs() {
		#if js
		try {
			// prefs = haxe.Unserializer.run(js.Browser.getLocalStorage().getItem("prefs"));
			if (prefs.recent == null)
				prefs.recent = [];
		} catch (e:Dynamic) {}
		#end
	}

	function savePrefs() {
		// js.Browser.getLocalStorage().setItem("prefs", haxe.Serializer.run(prefs));
	}

	function checkTime() {
		/*
			if( prefs.curFile == null )
				return;
			var fileTime = getFileTime();
			if( fileTime != lastSave && fileTime != 0 )
				load(); */
	}

	function getFileTime():Float {
		#if sys
		return try sys.FileSystem.stat(prefs.curFile).mtime.getTime() * 1.
		catch (e:Dynamic)
		0.;
		#else
		return 0;
		#end
	}

	public function setClipBoard( schema : Array<cdb.Data.Column>, data : Array<Dynamic> ) {
		clipboard = {
			text : Std.string([for( o in data ) shownSheetView().sheet.objToString(o,true)]),
			data : data,
			schema : schema,
		};
		#if js
		js.node.webkit.Clipboard.getInstance().set(clipboard.text, "text");
		#elseif openfl 
		openfl.desktop.Clipboard.generalClipboard.setData(openfl.desktop.ClipboardFormats.TEXT_FORMAT, clipboard.text);
		#end
	}
}
