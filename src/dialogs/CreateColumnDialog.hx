package dialogs;

import cdb.Data;
import haxe.ui.core.Component;
import haxe.ui.components.Label;
import haxe.ui.components.DropDown;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import components.SheetView;
import haxe.ui.containers.dialogs.Dialog;

import cdb.Sheet;
import cdb.Data.Column;
import cdb.Data.ColumnType;

using haxe.ui.animation.AnimationTools;

@xml('
<vbox>
<label text="Column Props" />
<grid columns="2" id="grid"> 
<label text="Column Name" />
<textfield id="column_name" text="" />

<label text="Column Type" />
<dropdown id="column_type" text="Choose" width="100%" >
<data>
<item text="Unique Identifier" type="id"/>
<item type="string" text="Text"/>
<item type="bool" text="Boolean"/>
<item type="int" text="Integer"/>
<item type="float" text="Float"/>
<item type="enum" text="Enumeration"/>
<item type="flags" text="Flags"/>
<item type="ref" text="Reference"/>
<item type="list" text="List"/>
<item type="properties" text="Properties"/>
<item type="color" text="Color"/>
<item type="file" text="File"/>
<item type="image" text="Image"/>
<item type="tilepos" text="Tile"/>
<item type="dynamic" text="Dynamic"/>
<item type="layer" text="Data Layer"/>
<item type="tilelayer" text="Tile Layer"/>
<item type="custom" text="Custom Type"/>
</data>
</dropdown>
</grid>
<checkbox id="required" text="Required" horizontalAlign="right"/>

</vbox>
')
class CreateColumnDialog extends Dialog {

    var col:Column = null;
    
    
    var valuesProp:String ="";
    var sheetProp:Sheet = null;  // For Refs


    public function new(sheetView:SheetView, col:Column = null, colIndex:Null<Int> = null) {
        super();
		defaultButton = "Create";
        this.col = col;
        buttons = DialogButton.CANCEL | "Create";
        if (col != null) {
            buttons = DialogButton.CANCEL | "Delete" | "Modify";
            column_name.text = col.name;
            var typeS = switch (col.type) {
                case TId:"id";
                case TString:"string";
                case TFloat: "float";
                case TEnum(_): "enum";
                case TFlags(_):"flags";
                case TInt: "int";
                case TBool : "bool";
                case TRef(_) : "ref";
                case TList: "list" ; 
                case TProperties: "properties";
                case TColor: "color";
                case TFile : "file";
                case TImage: "image";
                case TTilePos: "tilepos";
                case TDynamic: "dynamic";
                case TLayer(_): "layer";
                case TTileLayer: "tilelayer";
                case TCustom(_): "custom";
            }

            
            for ( i in 0...column_type.dataSource.size) {
                var dat = column_type.dataSource.get(i);
                if (dat.type == typeS) {
                    column_type.selectedIndex = i;
                    break;
                }
            }
        }
       



        onDialogClosed = function(e:DialogEvent) {
            
            trace(e.button);
            if (e.button == "Create") {
				if (column_type.selectedIndex < 0) {
					e.cancel();
					column_type.shake().flash();
					return;
				}
				Main.mainView.new_line.disabled = false;
                
                var column = createColumn(column_type.selectedItem.type, sheetView.sheet);
                column.name = column_name.text;
				column.opt  = !required.selected;
                var alert = sheetView.sheet.addColumn(column, colIndex);
                if (alert != null){
					haxe.ui.containers.dialogs.Dialogs.messageBox(alert, 'Error', 'error');
					e.cancel();
				}
                sheetView.refresh();
            }
            else if (e.button == "Delete") {
                SheetUtils.deleteColumn(sheetView.sheet,col);
                sheetView.refresh();
            }

            else if (e.button == "Modify") {
                sheetView.refresh();
            }

        }
    }

    @:bind(column_type, haxe.ui.events.UIEvent.CHANGE)
    private function onTypeSelect(e) {
        for (c in findComponents("type_custom", Component)) {
            c.parentComponent.removeComponent(c);
        }

        switch (column_type.selectedItem.type) {
            case "int", "float":
                var label = new Label();
                label.text = "Display";
                label.addClass("type_custom");
                grid.addComponent(label);
                var dropdown = new DropDown();
                dropdown.addClass("type_custom");
                dropdown.dataSource.add("Default");
                dropdown.dataSource.add("Percentage");
                grid.addComponent(dropdown);
				dropdown.onChange = function(e) {
					valuesProp = dropdown.selectedItem;
				}
                if (col!= null) {
                    
                }
            case "enum", "flags":
                var label = new Label();
                label.text = "Possible Values";
                label.addClass("type_custom");
                grid.addComponent(label);
                var textfield = new TextField();
                textfield.addClass("type_custom");
                grid.addComponent(textfield);
                textfield.onChange = function(e) {
                    valuesProp =  textfield.text;
                }
            case "ref":
                var label = new Label();
                label.text ="Sheet";
                label.addClass("type_custom");
                grid.addComponent(label);
                var dropdown = new DropDown();
				for (s in Main.mainView.base.sheets) {
					dropdown.dataSource.add({sheet:s, text:s.name});
				}
                dropdown.addClass("type_custom");
				dropdown.onChange = function (e) {
					valuesProp = dropdown.selectedItem.text;
				}
                grid.addComponent(dropdown);
            case _:


        }

    }
     /*

    public function valueHtml( c : Column, v : Dynamic, sheet : Sheet, obj : Dynamic ) : String {
		if( v == null ) {
			if( c.opt )
				return "&nbsp;";
			return '<span class="error">#NULL</span>';
		}
		return switch( c.type ) {
		case TInt, TFloat:
			switch( c.display ) {
			case Percent:
				(Math.round(v * 10000)/100) + "%";
			default:
				v + "";
			}
		case TId:
			v == "" ? '<span class="error">#MISSING</span>' : (base.getSheet(sheet.name).index.get(v).obj == obj ? v : '<span class="error">#DUP($v)</span>');
		case TString, TLayer(_):
			v == "" ? "&nbsp;" : StringTools.htmlEscape(v);
		case TRef(sname):
			if( v == "" )
				'<span class="error">#MISSING</span>';
			else {
				var s = base.getSheet(sname);
				var i = s.index.get(v);
				i == null ? '<span class="error">#REF($v)</span>' : (i.ico == null ? "" : tileHtml(i.ico,true)+" ") + StringTools.htmlEscape(i.disp);
			}
		case TBool:
			v?"Y":"N";
		case TEnum(values):
			values[v];
		case TImage:
			if( v == "" )
				'<span class="error">#MISSING</span>'
			else {
				var data = Reflect.field(imageBank, v);
				if( data == null )
					'<span class="error">#NOTFOUND($v)</span>'
				else
					'<img src="$data"/>';
			}
		case TList:
			var a : Array<Dynamic> = v;
			var ps = sheet.getSub(c);
			var out : Array<String> = [];
			var size = 0;
			for( v in a ) {
				var vals = [];
				for( c in ps.columns )
					switch( c.type ) {
					case TList, TProperties:
						continue;
					default:
						vals.push(valueHtml(c, Reflect.field(v, c.name), ps, v));
					}
				var v = vals.length == 1 ? vals[0] : ""+vals;
				if( size > 200 ) {
					out.push("...");
					break;
				}
				var vstr = v;
				if( v.indexOf("<") >= 0 ) {
					vstr = ~/<img src="[^"]+" style="display:none"[^>]+>/g.replace(vstr, "");
					vstr = ~/<img src="[^"]+"\/>/g.replace(vstr, "[I]");
					vstr = ~/<div id="[^>]+><\/div>/g.replace(vstr, "[D]");
				}
				size += vstr.length;
				out.push(v);
			}
			if( out.length == 0 )
				return "";
			return out.join(", ");
		case TProperties:
			var ps = sheet.getSub(c);
			var out = [];
			for( c in ps.columns ) {
				var pval = Reflect.field(v, c.name);
				if( pval == null && c.opt ) continue;
				out.push(c.name+" : "+valueHtml(c, pval, ps, v));
			}
			return out.join("<br/>");
		case TCustom(name):
			var t = base.getCustomType(name);
			var a : Array<Dynamic> = v;
			var cas = t.cases[a[0]];
			var str = cas.name;
			if( cas.args.length > 0 ) {
				str += "(";
				var out = [];
				var pos = 1;
				for( i in 1...a.length )
					out.push(valueHtml(cas.args[i-1], a[i], sheet, this));
				str += out.join(",");
				str += ")";
			}
			str;
		case TFlags(values):
			var v : Int = v;
			var flags = [];
			for( i in 0...values.length )
				if( v & (1 << i) != 0 )
					flags.push(StringTools.htmlEscape(values[i]));
			flags.length == 0 ? String.fromCharCode(0x2205) : flags.join("|<wbr>");
		case TColor:
			var id = UID++;
			'<div class="color" style="background-color:#${StringTools.hex(v,6)}"></div>';
		case TFile:
			var path = getAbsPath(v);
			var url = "file://" + path;
			var ext = v.split(".").pop().toLowerCase();
			var val = StringTools.htmlEscape(v);
			var html = v == "" ? '<span class="error">#MISSING</span>' : '<span title="$val">$val</span>';
			if( v != "" && !quickExists(path) )
				html = '<span class="error">' + html + '</span>';
			else if( ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "gif" )
				html = '<span class="preview">$html<div class="previewContent"><div class="label"></div><img src="$url" onload="$(this).parent().find(\'.label\').text(this.width+\'x\'+this.height)"/></div></span>';
			if( v != "" )
				html += ' <input type="submit" value="open" onclick="_.openFile(\'$path\')"/>';
			html;
		case TTilePos:
			return tileHtml(v);
		case TTileLayer:
			var v : cdb.Types.TileLayer = v;
			var path = getAbsPath(v.file);
			if( !quickExists(path) )
				'<span class="error">' + v.file + '</span>';
			else
				'#DATA';
		case TDynamic:
			var str = Std.string(v).split("\n").join(" ").split("\t").join("");
			if( str.length > 50 ) str = str.substr(0, 47) + "...";
			str;
		}
	}*/

    function createColumn(type:String, sheet:Sheet):Column {
        var v : Dynamic<String> = { };
        var columnType = switch(type) {
            case "id": TId;
		case "int": TInt;
		case "float": TFloat;
		case "string": TString;
		case "bool": TBool;
		case "enum":
			var vals = StringTools.trim(valuesProp).split(",");
			if( vals.length == 0 ) {
				//error("Missing value list");
				return null;
			}
			TEnum([for( f in vals ) StringTools.trim(f)]);
		case "flags":
			var vals = StringTools.trim(valuesProp).split(",");
			if( vals.length == 0 ) {
				//error("Missing value list");
				return null;
			}
			TFlags([for( f in vals ) StringTools.trim(f)]);
		case "ref":
			TRef(valuesProp);
		case "image":
			TImage;
		case "list":
			TList;
		case "custom":
			var t = Main.mainView.base.getCustomType(v.ctype);
			if( t == null ) {
				//error("Type not found");
				return null;
			}
			TCustom(t.name);
		case "color":
			TColor;
		case "layer":
			var s = Main.mainView.base.sheets[Std.parseInt(v.sheet)];
			if( s == null ) {
				//error("Sheet not found");
				return null;
			}
			TLayer(s.name);
		case "file":
			TFile;
		case "tilepos":
			TTilePos;
		case "tilelayer":
			TTileLayer;
		case "dynamic":
			TDynamic;
		case "properties":
			TProperties;
		default:
			return null;


        }

        var c : Column = {
			type : columnType,
			typeStr : null,
            name: ""
			//name:name //aname : v.name,
		};

		if (valuesProp == "Percentage") {
			c.display = DisplayType.Percent;
		}

        return c;

       // sheet.addColumn(c, colProps.index);
    }

    /*

    function createColumn() {

		var v : Dynamic<String> = { };
		var cols = J("#col_form input, #col_form select").not("[type=submit]");
		for( i in cols.elements() )
			Reflect.setField(v, i.attr("name"), i.attr("type") == "checkbox" ? (i.is(":checked")?"on":null) : i.val());

		var sheet = colProps.sheet == null ? viewSheet : getSheet(colProps.sheet);
		var refColumn = colProps.ref;

		var t : ColumnType = switch( v.type ) {
		
		}
		var c : Column = {
			type : t,
			typeStr : null,
			name : v.name,
		};
		if( v.req != "on" ) c.opt = true;
		if( v.display != "0" ) c.display = cast Std.parseInt(v.display);
		if( v.localizable == "on" ) c.kind = Localizable;

		if( refColumn != null ) {
			var err = base.updateColumn(sheet, refColumn, c);
			if( err != null ) {
				// might have partial change
				refresh();
				save();
				error(err);
				return;
			}
		} else {
			var err = sheet.addColumn(c, colProps.index);
			if( err != null ) {
				error(err);
				return;
			}
			// automatically add to current selection
			if( sheet.props.isProps && cursor.s.columns == sheet.columns ) {
				var obj = cursor.s.lines[0];
				if( obj != null )
					Reflect.setField(obj, c.name, base.getDefault(c, true));
			}
		}

		J("#newcol").hide();
		for( c in cols.elements() )
			c.val("");
		refresh();
		save();
	}*/

}