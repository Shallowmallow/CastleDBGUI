package components;

interface IClickableCell {
    public function clickCell():Void;
    public function validateCell(focusNext:Bool = true):Void;
    public function isOpen():Bool;
    public function closeCell():Void;
}