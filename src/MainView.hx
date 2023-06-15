package;

import haxe.ui.Toolkit;
import haxe.ui.core.InteractiveComponent;
import components.TImageCell;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.HaxeUIApp;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import components.SheetView;
import haxe.io.Path;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import haxe.ui.events.AppEvent;
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
	public var clipboard:{
		text:String,
		data:Array<Dynamic>,
		schema:Array<Column>,
	};

	@:bind(menubar, MenuEvent.MENU_OPENED)
	private function addRecent(e) {
		mrecent.removeAllComponents();
		for (r in prefs.recent) {
			var menuItem = new MenuItem();
			menuItem.text = "" + r;
			menuItem.addClass("recent_file");
			mrecent.addComponent(menuItem);
		}
	}

	@:bind(menubar, MenuEvent.MENU_SELECTED)
	private function onSelectMenu(e:MenuEvent) {
		switch (e.menuItem.id) {
			case "mnew":
				prefs.curFile = null;
				load(true);
			case "mexit":
				#if sys Sys.exit(0); #end
			case "mclean":
				cleanImages();
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
						#if sys
						name: Sys.getEnv("HOME"),
						#end
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
		}
		if (e.menuItem.hasClass("recent_file")) {
			prefs.curFile = e.menuItem.text;
			load();
		}
	}

	public var base:cdb.Database = new cdb.Database();

	public var prefs:Prefs;
	public var imageBank:Dynamic<String>; // Why a dynamic string and not a map ?

	var openedList:Map<String, Bool>;
	var existsCache:Map<String, {t:Float, r:Bool}>;

	public var curSavedData:HistoryElement;
	public var history:Array<HistoryElement> = [];
	public var redo:Array<HistoryElement> = [];

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
				return;
			}

			// TODO ideally should have some special hover effects
			// But in lime there isn"t a dropfile window ghas entered event yet

			trace(screen.currentMouseX, screen.currentMouseY);

			//  needs a callLater or the currentMouseX won't be updated
			Toolkit.callLater(function () {
			var components = findComponentsUnderPoint(screen.currentMouseX, screen.currentMouseY);
			trace(components);
			for ( c in components) {
				if ( c is FocusableItemRenderer) {
					var image = c.findComponents(TImageCell)[0];
					if (image != null) {
						// needs to check if file I think it should be haxeui doing it
						image.image.resource = path;
						image.validateCell();
						Main.mainView.save();
					}
				}
			} });


		});
		#end

		HaxeUIApp.instance.registerEvent(AppEvent.APP_EXITED, function f(e) {
			savePrefs();
		});
	}

	@:bind(this, MouseEvent.MOUSE_MOVE)
	private function mouseMove(e:MouseEvent) {
//		trace(e.screenY);
//		trace(screen.currentMouseY);
	}

	@:bind(this, UIEvent.READY)
	private function firstLoad(e) {
		load(true);
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
		// check if sideview with list
		if (!sideview.hidden) {
			// if sideview has a sheet/list opened
			if (sideview.findComponents(components.SheetView).length > 0) {
				sideview.findComponents(components.SheetView)[0].addLine(e);
				return;
			}

		}
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
		if (history)
			saveWithHistory(sdata);

		if (prefs.curFile == null)
			return;
		#if sys
		var tmp = Sys.getEnv("TMP");
		if (tmp == null)
			tmp = Sys.getEnv("TMPDIR");
		var tmpFile = tmp + "/" + prefs.curFile.split("\\").join("/").split("/").pop() + ".lock";
		try
			sys.io.File.saveContent(tmpFile, "LOCKED by CDB")
		catch (e:Dynamic) {};
		try {
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
		#end
		lastSave = getFileTime();
	}

	public function saveImages() {
		if (prefs.curFile == null)
			return;
		var img = prefs.curFile.split(".");
		img.pop();
		trace(img);
		var path = img.join(".") + ".img";
		trace(path);
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
		#if sys
		if (sys.FileSystem.exists(prefs.curFile + ".mine") && !Resolver.resolveConflict(prefs.curFile)) {
			error("CDB file has unresolved conflict, merge by hand before reloading.");
			return;
		}
		#end

		lastSave = getFileTime();
		loadi(noError);

		// initContent();
		loadSheets();
		prefs.recent.remove(prefs.curFile);
		if (prefs.curFile != null)
			prefs.recent.unshift(prefs.curFile);
		if (prefs.recent.length > 8)
			prefs.recent.pop();

		/* TODO
			mcompress.checked = base.compress;mcompress = new MenuItem( { label : "Enable Compression", type : MenuItemType.checkbox } );
			mcompress.click = function() {
				base.compress = mcompress.checked;
				save();
			};

		 */
	}

	function loadi(noError = false) {
		history = [];
		redo = [];
		base = new cdb.Database();
		#if sys
		try {
			base.load(sys.io.File.getContent(prefs.curFile));
			if (prefs.curSheet > base.sheets.length)
				prefs.curSheet = 0;
			else {
				trace(prefs.curSheet, base.sheets.length);
				while (base.sheets[prefs.curSheet] != null && base.sheets[prefs.curSheet].props.hide) {
					prefs.curSheet--;
				}
			}
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
	}

	function loadSheets() {
		Main.mainView.tabs.removeAllPages();
		for (sheet in base.sheets) {
			if (sheet.props.hide)
				continue;
			trace(sheet);
			var sheetView = createSheetView(sheet);
			sheetView.registerEvent(UIEvent.READY, function(e) { // Or it will bug incase there is already some data in the sheet
				sheetView.refresh();
			});
			// sheetView.refresh();
			sheetView.addClass("non-closable");

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
		trace(used);
		for (f in Reflect.fields(imageBank))
			if (!used.get(f))
				Reflect.deleteField(imageBank, f);
		saveImages();
	}

	function loadPrefs() {
		#if (sys && linux)
		try {
			prefs = haxe.Unserializer.run(File.getContent(Sys.getEnv("HOME") + "/.config/castledb/prefs"));
			if (prefs.recent == null)
				prefs.recent = [];
		} catch (e:Dynamic) {}
		#end
		#if js
		try {
			// prefs = haxe.Unserializer.run(js.Browser.getLocalStorage().getItem("prefs"));
			if (prefs.recent == null)
				prefs.recent = [];
		} catch (e:Dynamic) {}
		#end
	}

	function savePrefs() {
		#if (sys && linux)
		if (!FileSystem.exists(Sys.getEnv("HOME") + "/.config")) {
			FileSystem.createDirectory(Sys.getEnv("HOME") + "/.config");
		}
		if (!FileSystem.exists(Sys.getEnv("HOME") + "/.config/castledb")) {
			FileSystem.createDirectory(Sys.getEnv("HOME") + "/.config/castledb");
		}

		// TODO, should have a normal ini file I think
		File.saveContent(Sys.getEnv("HOME") + "/.config/castledb/prefs", haxe.Serializer.run(prefs));
		#end
		#if js
		// js.Browser.getLocalStorage().setItem("prefs", haxe.Serializer.run(prefs));
		#end
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

	public function setClipBoard(schema:Array<cdb.Data.Column>, data:Array<Dynamic>) {
		clipboard = {
			text: Std.string([for (o in data) shownSheetView().sheet.objToString(o, true)]),
			data: data,
			schema: schema,
		};
		#if node
		js.node.webkit.Clipboard.getInstance().set(clipboard.text, "text");
		#elseif openfl
		openfl.desktop.Clipboard.generalClipboard.setData(openfl.desktop.ClipboardFormats.TEXT_FORMAT, clipboard.text);
		#end
	}

	public function undo() {
		trace(history.length);
		if (history.length > 0) {
			for (i in 0...tabs.pageCount) {
				var sheetView:SheetView = cast(tabs.getPage(i), SheetView);
				sheetView.sheetName = sheetView.sheet.name;
			}
			redo.push(curSavedData);
			curSavedData = Main.mainView.history.pop();
			quickLoad(curSavedData);
			refreshSheets();
			save(false);
		}
	}

	public function redoFunc() {
		if (redo.length > 0) {
			for (i in 0...tabs.pageCount) {
				var sheetView:SheetView = cast(tabs.getPage(i), SheetView);
				sheetView.sheetName = sheetView.sheet.name;
			}
			history.push(curSavedData);
			curSavedData = redo.pop();
			quickLoad(curSavedData);
			refreshSheets();
			save(false);
		}
	}

	function refreshSheets() {
		for (i in 0...tabs.pageCount) {
			var sheetView:SheetView = cast(tabs.getPage(i), SheetView);
			var sheet = base.getSheet(sheetView.sheetName);
			sheetView.sheet = sheet;
			sheetView.refresh();
		}
	}
}
