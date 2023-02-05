package popups;

import components.SheetView;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuCheckBox;

@:xml('
<menu>
    <menuitem id="nins" text="AddSheet"/>
    <menuitem id="nleft" text="Move Left"/>
    <menuitem id="nright" text="Move Right"/>
    <menuitem id="nren" text="Rename"/>
    <menuitem id="ndel" text="Delete"/>
    <menucheckbox id="nindex" text="Add Index"/>
    <menucheckbox id="ngroup" text="Add Group"/>
</menu>
')
class SheetPopup extends Menu {

    public function new(sheetView:SheetView) {
        super();

        var base = Main.mainView.base;
        var s = sheetView.sheet;
        var prefs = Main.mainView.prefs;
        var save = Main.mainView.save;

        nleft.onClick = function(e) {
            var prev = -1;
            for( i in 0...base.sheets.length ) {
                var s2 = base.sheets[i];
                if( s == s2 ) break;
                if( !s2.props.hide ) prev = i;
            }
            if( prev < 0 ) return;
            base.sheets.remove(s);
            base.sheets.insert(prev, s);
            base.updateSheets();
            prefs.curSheet = prev;
            //TODO initContent();
            save();
        };

        nright.onClick = function(e) {
            var sheets = [for( s in base.sheets ) if( !s.props.hide ) s];
            var index = sheets.indexOf(s);
            var next = sheets[index+1];
            if( index < 0 || next == null ) return;
            base.sheets.remove(s);
            index = base.sheets.indexOf(next) + 1;
            base.sheets.insert(index, s);
    
            // move sub sheets as well !
            var moved = [s];
            var delta = 0;
            for( ssub in base.sheets.copy() ) {
                var parent = ssub.getParent();
                if( parent != null && moved.indexOf(parent.s) >= 0 ) {
                    base.sheets.remove(ssub);
                    var idx = base.sheets.indexOf(s) + (++delta);
                    base.sheets.insert(idx, ssub);
                    moved.push(ssub);
                }
            }
    
            base.updateSheets();
            prefs.curSheet = base.sheets.indexOf(s);
            // TODO initContent();
            save();
        }

        ndel.onClick = function(e) {
            base.deleteSheet(s);
            // TODO initContent();
            save();
        };

        nins.onClick = function(e) {
            // TODO newSheet();
        };

        nindex.selected = s.props.hasIndex;

        nindex.onClick = function(e) {
            if( s.props.hasIndex ) {
                for( o in s.getLines() )
                    Reflect.deleteField(o, "index");
                s.props.hasIndex = false;
            } else {
                for( c in s.columns )
                    if( c.name == "index" ) {
                        // TODO error("Column 'index' already exists");
                        return;
                    }
                s.props.hasIndex = true;
            }
            save();
        };

    ngroup.selected = s.props.hasGroup;
    ngroup.onClick = function(e) {
        if( s.props.hasGroup ) {
            for( o in s.getLines() )
                Reflect.deleteField(o, "group");
            s.props.hasGroup = false;
        } else {
            for( c in s.columns )
                if( c.name == "group" ) {
                   // TODO error("Column 'group' already exists");
                    return;
                }
            s.props.hasGroup = true;
        }
        save();
    };

    nren.onClick = function(e) {
        //li.dblclick();
    };

    if( s.isLevel() || (s.hasColumn("width", [TInt]) && s.hasColumn("height", [TInt]) && s.hasColumn("props",[TDynamic])) ) {
        var nlevel = new MenuCheckBox();
        nlevel.text = "Level";
        nlevel.selected = s.isLevel();
        addComponent(nlevel);
        nlevel.onClick = function(e) {
            if( s.isLevel() )
                Reflect.deleteField(s.props, "level");
            else
                s.props.level = {
                    tileSets : {},
                }
            save();
//            sheetView.refresh();
        };
    }


    }


}

/*
    
    
    
    
    
    
    
    

    n.popup(mousePos.x, mousePos.y);
}*/