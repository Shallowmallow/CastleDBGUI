package popups;

import haxe.ui.containers.menus.Menu;
import components.SheetView;

@:xml('
<menu>
<menuitem id="nup" text="Move Up"/>
<menuitem id="ndown" text="Move Down"/>
    <menuitem id="nins" text="Insert"/>
    <menuitem id="ndel" text="Delete"/>
    <menuitem id="nren" text="Rename"/>
    <menucheckbox id="nsep" text="Separator"/>
    <menucheckbox id="nref" text="Show References"/>
</menu>
')
class LinePopup extends Menu {
    public function new(sheetView:SheetView, index:Int) {
        super();
    }
}

/*

function popupLine( sheet : Sheet, index : Int ) {
    var sepIndex = Lambda.indexOf(sheet.separators, index);
    nsep.checked = sepIndex >= 0;
    nins.click = function() {
        newLine(sheet, index);
    };
    nup.click = function() {
        moveLine(sheet, index, -1);
    };
    ndown.click = function() {
        moveLine(sheet, index, 1);
    };
    ndel.click = function() {
        sheet.deleteLine(index);
        refresh();
        save();
    };
    nsep.click = function() {
        if( sepIndex >= 0 ) {
            sheet.separators.splice(sepIndex, 1);
            if( sheet.props.separatorTitles != null ) sheet.props.separatorTitles.splice(sepIndex, 1);
        } else {
            sepIndex = sheet.separators.length;
            for( i in 0...sheet.separators.length )
                if( sheet.separators[i] > index ) {
                    sepIndex = i;
                    break;
                }
            sheet.separators.insert(sepIndex, index);
            if( sheet.props.separatorTitles != null && sheet.props.separatorTitles.length > sepIndex )
                sheet.props.separatorTitles.insert(sepIndex, null);
        }
        refresh();
        save();
    };
    nref.click = function() {
        showReferences(sheet, index);
    };
    if( sheet.props.hide )
        nsep.enabled = false;
    n.popup(mousePos.x, mousePos.y);
}*/