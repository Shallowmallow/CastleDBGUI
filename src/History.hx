import haxe.ui.data.transformation.IItemTransformer;
import MainView.HistoryElement2;
import haxe.ui.containers.VBox;
import haxe.ui.data.ArrayDataSource;

@:xml('
<vbox>
<label text="rere"/>
<listview id="list" virtual="true" width="100%" contentWidth="100%" height="100%"/>
</vbox>
')
class History extends VBox {

    @:bind(this, haxe.ui.events.UIEvent.SHOWN)
    public function bindData(_) {
        var history  = Main.mainView.history2.copy();
        history.reverse(); 
        list.dataSource = ArrayDataSource.fromArray( history, new MyTypeTransformer());
    }

    public function updateHistory() {
        var history  = Main.mainView.history2.copy();
        history.reverse(); 
        list.dataSource = ArrayDataSource.fromArray(history, new MyTypeTransformer());
        trace("update history");
        list.invalidateComponent();
    }


}

class MyTypeTransformer implements IItemTransformer<HistoryElement2> {
    public function new() {
    }

    public function transformFrom(h:HistoryElement2):Dynamic {

        switch (h) {

            case  ChangedField(sheet,id, lineIndex,previousValue,newValue):

                var col  = SheetUtils.getColumnForName(sheet, id);  
                trace(col.type.getName(), col.typeStr);
                return { text: 'sheet ${sheet.name} line $lineIndex id $id (${col.type.getName()}) to $newValue', value: h };
            default:
        } 
        return { text: "action", value: "ta" };
    }

}