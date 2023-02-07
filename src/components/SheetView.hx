package components;

import haxe.ui.Toolkit;
import haxe.ui.containers.HBox;
import haxe.ui.focus.FocusManager;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.components.popups.ColorPickerPopup;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Button;
import haxe.ui.data.DataSource;
import haxe.ui.components.Label;
import haxe.ui.core.ItemRenderer;
import haxe.ui.core.Component;
import dialogs.CreateColumnDialog;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import cdb.Data.Column as CdbCol;
import cdb.Data;
import cdb.Sheet;

/*
	private typedef Cursor = {
	x:Int,
	y:Int,
	?select:{x:Int, y:Int},
	?onchange:Void->Void,
}*/
class Cursor {
	public var sheetView:SheetView = null;
	public var x(default, set):Int = 0;
	public var y(default, set):Int = 0;

	public var select(default, set):{x:Int, y:Int} = null;

	private function set_select(select:{x:Int, y:Int}) {
		this.select = select;
			for (c in sheetView.table.findComponents(FocusableItemRenderer)) {
				c.removeClass(":selected");
			}
			if (select == null) return null;
		var selection = getSelection();
		for ( x in selection.x1...selection.x2 +1) {
			for ( y in selection.y1...selection.y2 +1) {
				for (c in sheetView.table.findComponents(FocusableItemRenderer)) {
					var compoundRenderer = cast(c.parentComponent, ItemRenderer);
		
					if (compoundRenderer.itemIndex == y) {
						var cc = compoundRenderer.findComponents(FocusableItemRenderer, 1);
						var xIndex = cc.indexOf(c);
						if (xIndex == x)
							c.addClass(":selected");
					}
				};

			}
		}
		return select;
	}

	public function getSelection() {
		var x1 = if (x < 0) 0 else x;
		var x2 = if (x < 0) sheetView.sheet.columns.length - 1 else if (select != null) select.x else x1;
		var y1 = y;
		var y2 = if (select != null) select.y else y1;
		if (x2 < x1) {
			var tmp = x2;
			x2 = x1;
			x1 = tmp;
		}
		if (y2 < y1) {
			var tmp = y2;
			y2 = y1;
			y1 = tmp;
		}
		return {
			x1: x1,
			x2: x2,
			y1: y1,
			y2: y2
		};
	}



	public function new(sheetView:SheetView) {
		this.sheetView = sheetView;
	}

	private function set_x(x:Int) {
		closeCell();
		if (rendererForCursor() != null)
			rendererForCursor().removeClass(":cursored");
		this.x = x;
		if (rendererForCursor() != null)
			rendererForCursor().addClass(":cursored");
		return x;
	}

	private function set_y(y:Int) {
		closeCell();
		if (rendererForCursor() != null)
			rendererForCursor().removeClass(":cursored");
		this.y = y;
		if (rendererForCursor() != null)
			rendererForCursor().addClass(":cursored");
		return y;
	}

	public function closeCell() {
		// should we save ???
		var r = rendererForCursor();
		if (r == null)
			return;
		var cell = r.getComponentAt(0);
		if ((cell is IClickableCell)) {
			if (cast(cell, IClickableCell).isOpen()) {
				cast(cell, IClickableCell).validateCell(false);
			}
		}
	}

	public function rendererForCursor() {
		for (c in sheetView.table.findComponents(FocusableItemRenderer)) {
			var compoundRenderer = cast(c.parentComponent, ItemRenderer);

			if (compoundRenderer.itemIndex == y) {
				var cc = compoundRenderer.findComponents(FocusableItemRenderer, 1);
				var xIndex = cc.indexOf(c);
				if (xIndex == x)
					return c;
			}
		}
		return null;
	}

	public function setToRenderer(r:FocusableItemRenderer) {
		var compoundRenderer = cast(r.parentComponent, ItemRenderer);
		y = compoundRenderer.itemIndex;
		var cc = compoundRenderer.findComponents(FocusableItemRenderer, 1);
		x = cc.indexOf(r);
	}

	public function moveDown() {
		if (y + 1 >= sheetView.table.dataSource.size) {
			return;
		}
		++y;
	}

	public function moveUp() {
		if (y <= 0) {
			return;
		}
		--y;
	}

	public function moveRight() {
		if (x + 1 >= sheetView.focusableColumnsNbr()) {
			return;
		}
		++x;
	}

	public function focusNext() {
		if (x + 1 < sheetView.focusableColumnsNbr()) {
			++x;
			return;
		}
		if (y + 1 < sheetView.table.dataSource.size) {
			++y;
			x = 0;
			return;
		}
	}

	public function moveLeft() {
		if (x <= 0) {
			return;
		}
		--x;
	}
}

@xml('
<vbox width="100%" height="100%">
<button id="add_column" text="add a column"/>
<tableview id="table" width="100%" height="100%" contentWidth="100%">
<header width="100%" id="header">
</header>>
</tableview>
</vbox>
')
class SheetView extends VBox {
	public var sheet:Sheet;
	public var cursor:Cursor; // = new Cursor(this);

	public function new() {
		super();
		cursor = new Cursor(this);

		// cursor.x = 0;
		// cursor.y = 0;
		cursor.sheetView = this;
		table.selectionMode = "disabled";
		table.allowFocus = false;
		// FocusManager.instance.enabled = false;
	}

	

	@:bind(add_column, MouseEvent.CLICK)
	private function addColumn(e) {
		var dia = new CreateColumnDialog(this);
		dia.show();
	}

	@:bind(table, haxe.ui.events.ItemEvent.COMPONENT_CHANGE_EVENT)
	private function changeCell(e:haxe.ui.events.ItemEvent) {
		trace("table change llalalala");
		if (!(e.sourceEvent.target is components.ICell))
			return;
		var itemCell = cast(e.sourceEvent.target, components.ICell);
		itemCell.saveCell(e.itemIndex);
	}

	// For some reason don't well in openfl where you need a background color

	/*
		@:bind(table, haxe.ui.events.ItemEvent.COMPONENT_CLICK_EVENT)
		private function clickCell(e:haxe.ui.events.ItemEvent) {
			trace("table click llalalala");
			trace(e.sourceEvent.target.findAncestor("clickable_cell", Component, "css"));
			if ((e.sourceEvent.target.findAncestor("clickable_cell", Component, "css") == null)){
				return;
				var itemCell = cast(e.sourceEvent.target.findAncestor("clickable_cell", Component, "css"), components.IClickableCell);
				itemCell.clickCell();
			}
	}*/
	@:bind(table, haxe.ui.events.MouseEvent.CLICK)
	private function clickTable(e:MouseEvent) {
		if (!e.shiftKey) {
			cursor.select = null;
		}
		var comps = findComponentsUnderPoint(e.screenX, e.screenY);
		for (c in comps) {
			if ((c.id == "cell")) {
				if (e.shiftKey) {
					var compoundRenderer = cast(c.parentComponent, ItemRenderer);
					var y = compoundRenderer.itemIndex;
					var cc = compoundRenderer.findComponents(FocusableItemRenderer, 1);
					var x = cc.indexOf(cast c);
					cursor.select = {x: x, y: y}
					trace(cursor.select);
					break;
				}

				var x = cursor.x;
				var y = cursor.y;
				cursor.setToRenderer(cast c);
				if (cursor.x == x && cursor.y == y) {
					if ((c.getComponentAt(0) is IClickableCell)) {
						var cell = cast(c.getComponentAt(0), IClickableCell);
						cell.clickCell();
					}
				}
			}
		}
	}

	public function refreshRenderers() {
		trace(sheet.lines);
		for (c in table.findComponents("tableview-contents", Component)) {
			c.onRightClick = function(event) {
				var menu = new popups.LinePopup(this, 0);
				menu.left = event.screenX;
				menu.top = event.screenY;
				menu.show();
			}
		}

		table.dataSource.clear();
		trace(sheet.lines);

		if (sheet.columns.length > 5) {
			table.percentContentWidth = null;
			header.percentWidth = null;
		}

		table.clearContents(true);

		if (sheet.isLevel()) {
			var column = table.addColumn("edit_button");
			column.customStyle.minWidth = 72;
			column.text = "";
		}

		var indexColumn = table.addColumn("num_index");
		indexColumn.text = "";
		indexColumn.allowFocus = false;
		if (sheet.columns.length == 0)
			indexColumn.percentWidth = 100;
		else
			indexColumn.customStyle.minWidth = 30;
		indexColumn.onRightClick = function(event) {
			var menu = new popups.ColumnPopup(this, null);
			menu.nedit.disabled = true;
			menu.nleft.disabled = true;
			menu.nright.disabled = true;
			menu.ndel.disabled = true;
			menu.left = event.screenX;
			menu.top = event.screenY;
			menu.show();
		}

		for (c in sheet.columns) {
			var name = c.name;
			if (!c.opt)
				name += "*";
			var column = table.addColumn(name);
			column.id = c.name;
			column.allowFocus = false;
			column.customStyle.minWidth = 100;
			if (sheet.columns.length > 5)
				column.customStyle.width = 100;
			if (sheet.columns.length <= 5)
				column.customStyle.percentWidth = 100;

			column.onRightClick = function(event) {
				var menu = new popups.ColumnPopup(this, c);
				menu.left = event.screenX;
				menu.top = event.screenY;
				menu.show();
			}
		}

		trace(sheet.lines);

		if (table.itemRenderer != null)
			table.itemRenderer.removeAllComponents();

		if (sheet.isLevel()) {
			var button = new Button();
			button.text = "Edit";
			button.id = "edit_button";
			var itemRenderer = new FocusableItemRenderer();
			itemRenderer.verticalAlign = "center";
			itemRenderer.addComponent(button);
			table.addComponent(itemRenderer);
		}

		var label = new TIndexCell();
		label.id = "num_index";
		label.horizontalAlign = "center";
		label.verticalAlign = "center";
		label.customStyle.minHeight = 30;
		label.width = 24;

		var itemRenderer = new ItemRenderer();
		itemRenderer.verticalAlign = "center";
		itemRenderer.addComponent(label);
		table.addComponent(itemRenderer);

		trace(sheet.lines);

		for (c in sheet.columns) {
			trace(c);
			addCdbColumn(c);
		}

		trace("eee");

		Toolkit.callLater(function f() {
			cursor.x = cursor.x;
			cursor.y = cursor.y;
		});
	}

	public function focusableColumnsNbr() {
		var cols = sheet.columns.length;
		if (sheet.isLevel())
			++cols;
		return cols;
	}

	public function refresh() {
		trace(sheet.lines);
		refreshRenderers();
		trace(sheet.lines);
		refreshData();
	}

	public function refreshData() {
		var i = 0;
		// Adding an index
		trace(sheet.lines);
		for (line in sheet.lines) {
			Reflect.setField(line, "num_index", i);
			i++;
		}
		trace(sheet.lines);
		table.dataSource = ArrayDataSource.fromArray(sheet.lines.copy());
		trace(table.dataSource);
		add_column.hidden = (sheet.columns.length != 0);
	}

	public function addLine(e) {
		trace(sheet.lines);
		sheet.newLine();
		trace(sheet.lines);
		refresh();
		trace(sheet.lines);
		Main.mainView.save();
		trace(sheet.lines);
	}

	public function addCdbColumn(cdbCol:CdbCol) {
		var component:Component = switch (cdbCol.type) {
			case TId:
				new TIdCell();
			case TString:
				new TStringCell();
			case TBool:
				new TBoolCell();
			case TInt:
				new TIntCell();
			// new TextField();//;
			case TFloat:
				new NumberStepper();
			// new TextField();//.restrictChars="0-9,.";
			case TEnum(values):
				var dropDown = new TEnumCell();
				dropDown.dataSource = ArrayDataSource.fromArray(values);
				dropDown;
			case TColor:
				new TColorCell();
			case TImage:
				new TImageCell();
			case TFile:
				new TFileCell();
			case TFlags(values):
				var tFlags = new TFlagsCell(values);
				tFlags.flags = values;
				tFlags;
			case TRef(sheet):
				var tRef = new TRefCell();
				tRef.sheetName = sheet;
				tRef;
			case TTilePos:
				new TTileCell();
			case _:
				new Label();
		}
		component.id = cdbCol.name;
		component.percentWidth = 100;
		// component.percentHeight = 100;
		component.verticalAlign = "center";
		var itemRenderer = new FocusableItemRenderer();
		// itemRenderer.customStyle.minHeight = 40;
		itemRenderer.percentHeight = 100; // open fl so that labels cover all surface  if label only ???
		itemRenderer.id = "cell";
		// itemRenderer.backgroundColor = 0xff0000;
		itemRenderer.verticalAlign = "center";
		// itemRenderer.width  = 100;

		var hbox = new HBox();
		hbox.addComponent(component);
		hbox.horizontalAlign = " center";
		itemRenderer.addComponent(component);
		table.addComponent(itemRenderer);
	}

	public function insertLine(index:Int) {
		sheet.newLine(index);
		refresh();
		Main.mainView.save();
	}


	public function paste(clipboard:{ text : String, data : Array<Dynamic>, schema : Array<Column>, }) {
/*
		if( cursor.s == null || clipboard == null || js.node.webkit.Clipboard.getInstance().get("text")  != clipboard.text )
			return;*/
		var base = Main.mainView.base;
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
			Main.mainView.save();

	}


	//// ---------------------------------  SHORTCUTS --------------------------------------- ////
	// 	@:bind(this, haxe.ui.events.KeyboardEvent.KEY_PRESS)
	// 	@:bind(this, haxe.ui.events.KeyboardEvent.KEY_DOWN)
	// 	private function shortcutKey(e:haxe.ui.events.KeyboardEvent) {
	// 		trace(e);
	// 		var focus = FocusManager.instance.focus;
	// 		if (focus == null) return;
	// 		trace(focus);
	// 		var component = cast (focus, Component);
	// 		trace(component.id);
	// 		if ((component is ICell)) {
	// 			trace(component.id);
	// 			var itemRenderer = cast(component.parentComponent.parentComponent, ItemRenderer);
	// 			trace(itemRenderer.itemIndex);
	// 			trace(component.classes);
	// 			if (e.keyCode == 45) {//Insert
	// //				insertLine(itemRenderer.itemIndex + 1);
	// 			}
	// 		}
	// 		if ((component is IClickableCell)) {
	// 			trace(component.id);
	// 			var itemRenderer = cast(component.parentComponent.parentComponent, ItemRenderer);
	// 			trace(itemRenderer.itemIndex);
	// 			trace(component.classes);
	// 			if (e.keyCode == 45) {//Insert
	// 				cast(component, IClickableCell).clickCell();
	// //				insertLine(itemRenderer.itemIndex + 1);
	// 			}
	// 		}
	// 	}
	/*function fillTable( content : JQuery, sheet : Sheet ) {


		for( cindex in 0...sheet.columns.length ) {


			var ctype = "t_" + types[Type.enumIndex(c.type)];
			for( index in 0...sheet.lines.length ) {
				var obj = sheet.lines[index];
				var val : Dynamic = Reflect.field(obj,c.name);
				var v = J("<td>").addClass(ctype).addClass("c");
				var l = lines[index];
				v.appendTo(l);

				updateClasses(v, c, val);

				var html = valueHtml(c, val, sheet, obj);
				if( html == "&nbsp;" ) v.text(" ") else if( html.indexOf('<') < 0 && html.indexOf('&') < 0 ) v.text(html) else v.html(html);
				v.data("index", cindex);
				v.click(function(e) {
					if( inTodo ) {
						// nothing
					} else if( e.shiftKey && cursor.s == sheet ) {
						cursor.select = { x : cindex, y : index };
						updateCursor();
						e.stopImmediatePropagation();
					} else
						setCursor(sheet, cindex, index);
					e.stopPropagation();
				});

				function set(val2:Dynamic) {
					var old = val;
					val = val2;
					if( val == null )
						Reflect.deleteField(obj, c.name);
					else
						Reflect.setField(obj, c.name, val);
					html = valueHtml(c, val, sheet, obj);
					v.html(html);
					this.changed(sheet, c, index, old);
				}

				switch( c.type ) {
				case TImage:
					v.find("img").addClass("deletable").change(function(e) {
						if( Reflect.field(obj,c.name) != null ) {
							Reflect.deleteField(obj, c.name);
							refresh();
							save();
						}
					}).click(function(e) {
						JTHIS.addClass("selected");
						e.stopPropagation();
					});
					v.dblclick(function(_) editCell(c, v, sheet, index));
					v[0].addEventListener("drop", function(e : js.html.DragEvent ) {
						e.preventDefault();
						e.stopPropagation();
						if (e.dataTransfer.files.length > 0) {
							untyped v.dropFile = e.dataTransfer.files[0].path;
							editCell(c, v, sheet, index);
							untyped v.dropFile = null;
						}
					});
				case TList:
					var key = sheet.getPath() + "@" + c.name + ":" + index;
					v.click(function(e) {
						var next = l.next("tr.list");
						if( next.length > 0 ) {
							if( next.data("name") == c.name ) {
								next.change();
								return;
							}
							next.change();
						}
						next = J("<tr>").addClass("list").data("name", c.name);
						J("<td>").appendTo(next);
						var cell = J("<td>").attr("colspan", "" + colCount).appendTo(next);
						var div = J("<div>").appendTo(cell);
						if( !inTodo )
							div.hide();
						var content = J("<table>").appendTo(div);
						var psheet = sheet.getSub(c);
						if( val == null ) {
							val = [];
							Reflect.setField(obj, c.name, val);
						}
						psheet = new cdb.Sheet(base,{
							columns : psheet.columns, // SHARE
							props : psheet.props, // SHARE
							name : psheet.name, // same
							lines : val, // ref
							separators : [], // none
						},key, { sheet : sheet, column : cindex, line : index });
						fillTable(content, psheet);
						next.insertAfter(l);
						v.text("...");
						openedList.set(key,true);
						next.change(function(e) {
							if( c.opt && val.length == 0 ) {
								val = null;
								Reflect.deleteField(obj, c.name);
								save();
							}
							html = valueHtml(c, val, sheet, obj);
							v.html(html);
							div.slideUp(100, function() next.remove());
							openedList.remove(key);
							e.stopPropagation();
						});
						if( inTodo ) {
							// make sure we use the same instance
							if( cursor.s != null && cursor.s.getPath() == psheet.getPath() ) {
								cursor.s = psheet;
								checkCursor = false;
							}
						} else {
							div.slideDown(100);
							setCursor(psheet);
						}
						e.stopPropagation();
					});
					if( openedList.get(key) )
						todo.push(function() v.click());
				case TProperties:


					var key = sheet.getPath() + "@" + c.name + ":" + index;
					v.click(function(e) {
						var next = l.next("tr.list");
						if( next.length > 0 ) {
							if( next.data("name") == c.name ) {
								next.change();
								return;
							}
							next.change();
						}
						next = J("<tr>").addClass("list").data("name", c.name);
						J("<td>").appendTo(next);
						var cell = J("<td>").attr("colspan", "" + colCount).appendTo(next);
						var div = J("<div>").appendTo(cell);
						if( !inTodo )
							div.hide();
						var content = J("<table>").addClass("props").appendTo(div);
						var psheet = sheet.getSub(c);
						if( val == null ) {
							val = {};
							Reflect.setField(obj, c.name, val);
						}

						psheet = new cdb.Sheet(base,{
							columns : psheet.columns, // SHARE
							props : psheet.props, // SHARE
							name : psheet.name, // same
							lines : [for( f in Reflect.fields(val) ) null], // create as many fake lines as properties (for cursor navigation)
							separators : [], // none
						}, key, { sheet : sheet, column : cindex, line : index });
						@:privateAccess psheet.sheet.lines[0] = val; // ref
						fillProps(content, psheet, val);
						next.insertAfter(l);
						v.text("...");
						openedList.set(key,true);
						next.change(function(e) {
							if( c.opt && Reflect.fields(val).length == 0 ) {
								val = null;
								Reflect.deleteField(obj, c.name);
								save();
							}
							html = valueHtml(c, val, sheet, obj);
							v.html(html);
							div.slideUp(100, function() next.remove());
							openedList.remove(key);
							e.stopPropagation();
						});
						if( inTodo ) {
							// make sure we use the same instance
							if( cursor.s != null && cursor.s.getPath() == psheet.getPath() ) {
								cursor.s = psheet;
								checkCursor = false;
							}
						} else {
							div.slideDown(100);
							setCursor(psheet);
						}
						e.stopPropagation();
					});
					if( openedList.get(key) )
						todo.push(function() v.click());

				case TLayer(_):
					// nothing
				case TFile:
					v.find("input").addClass("deletable").change(function(e) {
						if( Reflect.field(obj,c.name) != null ) {
							Reflect.deleteField(obj, c.name);
							refresh();
							save();
						}
					});
					v.dblclick(function(_) {
						chooseFile(function(path) {
							set(path);
							save();
						});
					});
					v[0].addEventListener("drop", function( e : js.html.DragEvent ) {
						if ( e.dataTransfer.files.length > 0 ) {
							e.preventDefault();
							e.stopPropagation();
							var path = untyped e.dataTransfer.files[0].path;
							var relPath = makeRelativePath(path);
							set(relPath);
							save();
						}
					});
				case TTilePos:

					v.find("div").addClass("deletable").change(function(e) {
						if( Reflect.field(obj,c.name) != null ) {
							Reflect.deleteField(obj, c.name);
							refresh();
							save();
						}
					});

					v.dblclick(function(_) {
						var rv : cdb.Types.TilePos = val;
						var file = rv == null ? null : rv.file;
						var size = rv == null ? 16 : rv.size;
						var posX = rv == null ? 0 : rv.x;
						var posY = rv == null ? 0 : rv.y;
						var width = rv == null ? null : rv.width;
						var height = rv == null ? null : rv.height;
						if( width == null ) width = 1;
						if( height == null ) height = 1;
						if( file == null ) {
							var i = index - 1;
							while( i >= 0 ) {
								var o = sheet.lines[i--];
								var v2 = Reflect.field(o, c.name);
								if( v2 != null ) {
									file = v2.file;
									size = v2.size;
									break;
								}
							}
						}

						function setVal() {
							var v : Dynamic = { file : file, size : size, x : posX, y : posY };
							if( width != 1 ) v.width = width;
							if( height != 1 ) v.height = height;
							set(v);
						}

						if( file == null ) {
							chooseFile(function(path) {
								file = path;
								setVal();
								v.dblclick();
							});
							return;
						}
						var dialog = J(J(".tileSelect").parent().html()).prependTo(J("body"));

						var maxWidth = 1000000, maxHeight = 1000000;

						dialog.find(".tileView").css( { backgroundImage : 'url("file://${getAbsPath(file)}")' } ).mousemove(function(e) {
							var off = JTHIS.offset();
							posX = size == 1 ? Std.int((e.pageX - off.left)/width)*width : Std.int((e.pageX - off.left)/size);
							posY = size == 1 ? Std.int((e.pageY - off.top)/height)*height : Std.int((e.pageY - off.top) / size);
							if( (posX + width) * size > maxWidth )
								posX = Std.int(maxWidth / size) - width;
							if( (posY + height) * size > maxHeight )
								posY = Std.int(maxHeight / size) - height;
							if( posX < 0 ) posX = 0;
							if( posY < 0 ) posY = 0;
							J(".tileCursor").not(".current").css({
								marginLeft : (size * posX - 1) + "px",
								marginTop : (size * posY - 1) + "px",
							});
						}).click(function(_) {
							setVal();
							dialog.remove();
							save();
						});
						dialog.find("[name=size]").val("" + size).change(function(_) {
							size = Std.parseInt(JTHIS.val());
							J(".tileCursor").css( { width:(size*width)+"px", height:(size*height)+"px" } );
							J(".tileCursor.current").css( { marginLeft : (size * posX - 2) + "px", marginTop : (size * posY - 2) + "px" } );
						}).change();
						dialog.find("[name=width]").val("" + width).change(function(_) {
							width = Std.parseInt(JTHIS.val());
							J(".tileCursor").css( { width:(size*width)+"px", height:(size*height)+"px" } );
						}).change();
						dialog.find("[name=height]").val("" + height).change(function(_) {
							height = Std.parseInt(JTHIS.val());
							J(".tileCursor").css( { width:(size*width)+"px", height:(size*height)+"px" } );
						}).change();
						dialog.find("[name=cancel]").click(function(_) dialog.remove());
						dialog.find("[name=file]").click(function(_) {
							chooseFile(function(f) {
								file = f;
								dialog.remove();
								setVal();
								save();
								v.dblclick();
							});
						});
						dialog.keydown(function(e) e.stopPropagation()).keypress(function(e) e.stopPropagation());
						dialog.show();

						var i = js.Browser.document.createImageElement();
						i.onload = function(_) {
							maxWidth = i.width;
							maxHeight = i.height;
							dialog.find(".tileView").height(i.height).width(i.width);
							dialog.find(".tilePath").text(file+" (" + i.width + "x" + i.height + ")");
						};
						i.src = "file://" + getAbsPath(file);

					});


				default:
					v.dblclick(function(e) editCell(c, v, sheet, index));
				}
			}
		}

		if( sheet.lines.length == 0 ) {
			var l = J('<tr><td colspan="${sheet.columns.length + 1}"><a href="javascript:_.insertLine()">Insert Line</a></td></tr>');
			l.find("a").click(function(_) setCursor(sheet));
			lines.push(l);
		}

		if( sheet.isLevel() ) {
			var col = J("<td style='width:35px'>");
			cols.prepend(col);
			for( index in 0...sheet.lines.length ) {
				var l = lines[index];
				var c = J("<input type='submit' value='Edit'>");
				J("<td>").append(c).prependTo(l);
				c.click(function(_) {
					l.click();
					var found = null;
					for( l in levels )
						if( l.sheet == sheet && l.index == index )
							found = l;
					if( found == null ) {
						found = new Level(this, sheet, index);
						levels.push(found);
						selectLevel(found);
						initContent(); // refresh tabs
					} else
						selectLevel(found);
				});
			}
		}

		content.empty();
		content.append(cols);

		var snext = 0;
		for( i in 0...lines.length ) {
			while( sheet.separators[snext] == i ) {
				var sep = J("<tr>").addClass("separator").append('<td colspan="${colCount+1}">').appendTo(content);
				var content = sep.find("td");
				var title = if( sheet.props.separatorTitles != null ) sheet.props.separatorTitles[snext] else null;
				if( title != null ) content.text(title);
				var pos = snext;
				sep.dblclick(function(e) {
					content.empty();
					J("<input>").appendTo(content).focus().val(title == null ? "" : title).blur(function(_) {
						title = JTHIS.val();
						JTHIS.remove();
						content.text(title);
						var titles = sheet.props.separatorTitles;
						if( titles == null ) titles = [];
						while( titles.length < pos )
							titles.push(null);
						titles[pos] = title == "" ? null : title;
						while( titles[titles.length - 1] == null && titles.length > 0 )
							titles.pop();
						if( titles.length == 0 ) titles = null;
						sheet.props.separatorTitles = titles;
						save();
					}).keypress(function(e) {
						e.stopPropagation();
					}).keydown(function(e) {
						if( e.keyCode == 13 ) { JTHIS.blur(); e.preventDefault(); } else if( e.keyCode == 27 ) content.text(title);
						e.stopPropagation();
					});
				});
				snext++;
			}
			content.append(lines[i]);
		}

		inTodo = true;
		for( t in todo ) t();
		inTodo = false;
	}*/
	/*
		public function initContent() {
			(untyped J("body").spectrum).clearAll();
			var sheets = J("ul#sheets");
			sheets.children().remove();
			for( i in 0...base.sheets.length ) {
				var s = base.sheets[i];
				if( s.props.hide ) continue;
				var li = J("<li>");
				li.text(s.name).attr("id", "sheet_" + i).appendTo(sheets).click(function(_) selectSheet(s)).dblclick(function(_) {
					li.empty();
					J("<input>").val(s.name).appendTo(li).focus().blur(function(_) {
						li.text(s.name);
						var name = JTHIS.val();
						if( !base.r_ident.match(name) ) {
							error("Invalid sheet name");
							return;
						}
						var f = base.getSheet(name);
						if( f != null ) {
							if( f != s ) error("Sheet name already in use");
							return;
						}
						var old = s.name;
						s.rename(name);

						base.mapType(function(t) {
							return switch( t ) {
							case TRef(o) if( o == old ):
								TRef(name);
							case TLayer(o) if( o == old ):
								TLayer(name);
							default:
								t;
							}
						});

						for( s in base.sheets )
							if( StringTools.startsWith(s.name, old + "@") )
								s.rename(name + "@" + s.name.substr(old.length + 1));

						initContent();
						save();
					}).keydown(function(e) {
						if( e.keyCode == 13 ) JTHIS.blur() else if( e.keyCode == 27 ) initContent();
						e.stopPropagation();
					}).keypress(function(e) {
						e.stopPropagation();
					});
				}).mousedown(function(e) {
					if( e.which == 3 ) {
						haxe.Timer.delay(popupSheet.bind(s,li),1);
						e.stopPropagation();
					}
				});
			}
			pages.updateTabs();
			var s = base.sheets[prefs.curSheet];
			if( s == null ) s = base.sheets[0];
			if( s != null ) selectSheet(s, false);

			var old = levels;
			var lcur = null;
			levels = [];
			for( level in old ) {
				if( base.getSheet(level.sheetPath) == null ) continue;
				var s = getSheet(level.sheetPath);
				if( s.lines.length < level.index )
					continue;
				var l = new Level(this, s, level.index);
				if( level == this.level ) lcur = l;
				levels.push(l);
				var li = J("<li>");
				var name = level.getName();
				if( name == "" ) name = "???";
				li.text(name).attr("id", "level_" + l.sheetPath.split(".").join("_") + "_" + l.index).appendTo(sheets).click(function(_) selectLevel(l));
			}

			if( pages.curPage >= 0 )
				pages.select();
			else if( lcur != null )
				selectLevel(lcur);
			else if( base.sheets.length == 0 )
				J("#content").html("<a href='javascript:_.newSheet()'>Create a sheet</a>");
			else
				refresh();
	}*/
}
