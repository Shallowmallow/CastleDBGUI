package components;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Label;
import haxe.ui.core.ItemRenderer;

class TIndexCell extends Label {

    @:bind(this, haxe.ui.events.UIEvent.READY)
    private function onSelected(e) {            
        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id);
        var render = findAncestor(ItemRenderer);
        var index = cast (render.parentComponent,ItemRenderer).itemIndex;

        text = "" +index;
    }

    public override function set_value(value:Dynamic):Dynamic {
        var sheet = findAncestor(SheetView).sheet;

        var col  = SheetUtils.getColumnForName(sheet, id);
        var render = findAncestor(ItemRenderer);
        var index = cast (render.parentComponent,ItemRenderer).itemIndex;
        //TODO
        return super.set_value("" + index);
    }


}