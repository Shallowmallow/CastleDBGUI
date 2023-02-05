package components;

import haxe.ui.components.TextField;
import haxe.ui.core.ItemRenderer;

class TIdCell extends TStringCell implements ICell {

    public function new() {
        super();
    }


    public override function set_value(value:Dynamic):Dynamic {
        /*if (value == "" ) {
            value = "MISSING";
        }*/
        if (value != null) {
            if (!Main.mainView.base.r_ident.match(value)) value = null;
        } 
        if ((value == null) || (value == "")) {
            text = "Missing";
        }
        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id); 
        trace(col);
        return super.set_value(value);
    }


}

/**
    case TId:
						base.r_ident.match(nv) ? nv : null;
**/