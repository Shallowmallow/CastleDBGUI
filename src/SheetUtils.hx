import cdb.Sheet;
import cdb.Data.Column;
import cdb.Data.ColumnType;

class SheetUtils {

    public static var error =  haxe.ui.containers.dialogs.Dialogs.messageBox.bind(_, 'Error', 'error');

    public static function createSheet( name : String, level : Bool ) {
		name = StringTools.trim(name);
		if( !Main.mainView.base.r_ident.match(name) ) {

            error('Invalid Sheet Name');
			return null;
		}
		var s = Main.mainView.base.createSheet(name);
		if( s == null ) {
            error('Sheet name already in use');
			return null;
		}
		Main.mainView.prefs.curSheet = Main.mainView.base.sheets.length - 1;
		s.sync();
		if( level ) initLevel(s);

		//initContent();
		Main.mainView.save();

        return s;
	}


    public static function  initLevel( s : Sheet ) {
		//var cols = [ {n:"text", t: TString} , { n : "width", t : TInt }, { n : "height", t : TInt }];// { n : "id", t : TId }];//, { n : "props", t : TDynamic }, { n : "tileProps", t : TList }, { n : "layers", t : TList } ];
		//trace(cols);
        var cols = [  { n : "ida", t : TId } , {n:"text", t: TString}, { n : "width", t : TInt }, { n : "height", t : TInt },  { n : "layers", t : TList } ];// , { n : "width", t : TInt }];//];
        var cols = [ { n : "width", t : TInt }, { n : "height", t : TInt } ];
		var cols = [  { n : "ida", t : TId } ,{n:"text", t: TString}, { n : "width", t : TInt }, { n : "height", t : TInt } ];
		
		for( c in cols ) {
			if( s.hasColumn(c.n) ) {
				if( !s.hasColumn(c.n, [c.t]) ) {
					error("Column " + c.n + " already exists but does not have type " + c.t);
					return;
				}
			} else {
				inline function mkCol(n, t) : Column return { name : n, type : t, typeStr : null };
				var col = mkCol(c.n, c.t);
				s.addColumn(col);
				if( c.n == "layers" ) {
					var s = s.getSub(col);
					s.addColumn(mkCol("name",TString));
					s.addColumn(mkCol("data",TTileLayer));
				}
			}
		}
		if( s.props.level == null )
			s.props.level = { tileSets : { } };
		if( s.lines.length == 0 && s.parent == null ) {
			var o : Dynamic = s.newLine();
			o.test="text";
            //o.ida ="lala";
            o.text = "text";
            //o.layers=84;
            //o.int = 128;
			o.width = 128;
			o.height = 128;
		}
	}

    public static function changed( sheet : Sheet, c : Column, index : Int, old : Dynamic ) {
		switch( c.type ) {
		case TImage:
			Main.mainView.saveImages();
		case TTilePos:
			// if we change a file that has moved, change it for all instances having the same file
			var obj = sheet.lines[index];
			var oldV : cdb.Types.TilePos = old;
			var newV : cdb.Types.TilePos = Reflect.field(obj, c.name);
            /*
			if( newV != null && oldV != null && oldV.file != newV.file && !sys.FileSystem.exists(getAbsPath(oldV.file)) && sys.FileSystem.exists(getAbsPath(newV.file)) ) {
				var change = false;
				for( i in 0...sheet.lines.length ) {
					var t : Dynamic = Reflect.field(sheet.lines[i], c.name);
					if( t != null && t.file == oldV.file ) {
						t.file = newV.file;
						change = true;
					}
				}
				//if( change ) refresh();
			}*/
			sheet.updateValue(c, index, old);
		default:
			sheet.updateValue(c, index, old);
		}
		Main.mainView.save();
	}


    public static function deleteColumn( sheet : Sheet, col:Column) {
		/*if( cname == null ) {
			//sheet = getSheet(colProps.sheet);
			cname = colProps.ref.name;
		}*/
		if( !sheet.deleteColumn(col.name) )
			return;
		Main.mainView.save();
	}


    public static function  moveLine( sheet : Sheet, index : Int, delta : Int ) {
		// remove opened list
        /*
		getLine(sheet, index).next("tr.list").change();
		var index = sheet.moveLine(index, delta);
		if( index != null ) {
			setCursor(sheet, -1, index, false);
			refresh();
			save();
		}*/
	}

    public static function getColumnForName(sheet:Sheet, cname:String)  {
        for( c in sheet.columns )
            if( c.name == cname ) {
                return c;
        }
        return null;
    }

}