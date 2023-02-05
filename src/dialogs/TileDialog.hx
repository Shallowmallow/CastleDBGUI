package dialogs;

import haxe.ui.core.Component;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;


@xml('
<vbox>
<hbox>
<numberstepper id="tile_size" pos="32"/>
<numberstepper id="tile_width" pos="1"/>
<numberstepper id="tile_height" pos="1"/>
<button id="file" text="load"/>
</hbox>
<absolute id="absolute">
<grid id="grid" />
<image id="image"/>
<box id="mouseBox" styleNames="box_selection"/>
<box id="selectedBox" styleNames="box_selected"/>
</absolute>
</vbox>
')
class TileDialog extends Dialog {
    private var _isOpen = false;
    //private var mouseBox = new Box();


    @:bind(file, MouseEvent.CLICK)
    private function loadFile(e) {
        haxe.ui.containers.dialogs.Dialogs.openFile(function(b, files) {
            _isOpen = false;
			if (b == haxe.ui.containers.dialogs.Dialog.DialogButton.OK) {
				image.resource = "file://" +files[0].fullPath;
                updateBoxes();
			}
		}, {
			extensions: [{extension: "*"}],
			readContents: false
		});
    }

    @:bind(tile_height, UIEvent.CHANGE)
    @:bind(tile_width, UIEvent.CHANGE)
    @:bind(tile_size, UIEvent.CHANGE)
    private function changeTileSize(e) {
        updateBoxes();
    }

    private function updateBoxes() {

        mouseBox.width  = tile_size.pos * tile_width.pos;
                mouseBox.height = tile_size.pos * tile_height.pos;


        /*

        for ( c in findComponents("box_selection", Component)) {
            c.parentComponent.removeComponent(c);
        }

        var w = Std.int(image.originalWidth / tile_size.pos + tile_width.pos) ;
        var h = Std.int(image.originalHeight / tile_size.pos + tile_height.pos) ;

        for (x in 0...w) {
            for (y in 0...h) {
                var box = new Box();
                box.addClass("box_selection");
                box.addClass("x_"+x);
                box.addClass("y_"+y);
                box.id = x+"_"+y;
                box.left = x * tile_size.pos;
                box.top  = y * tile_size.pos; 
                box.width  = tile_size.pos;
                box.height = tile_size.pos;
                box.onMouseOver = function (e) {
                    trace(box.id);
                    selectBox(x,y, Std.int(tile_width.pos), Std.int(tile_height.pos));
                }
                box.onMouseOut = function (e) {
                    trace("removebox" + box.id);
                    selectBox(x,y, Std.int(tile_width.pos), Std.int(tile_height.pos), false);
                }
                absolute.addComponent(box);
            }
        }
        */
    }

    @:bind(image, MouseEvent.MOUSE_OVER)
    private function mouseOverImage(e:MouseEvent) {
        trace(e.localX);
        trace(e.localY);
    }

    @:bind(image, MouseEvent.MOUSE_MOVE)
    private function mouseMoveImage(e:MouseEvent) {
        mouseBox.top = Std.int(e.localY/tile_size.pos) * tile_size.pos;
        mouseBox.left = Std.int(e.localX/tile_size.pos) * tile_size.pos;
        /*
        trace(e.localX);
        trace();*/
    }

    @:bind(image, MouseEvent.CLICK)
    private function mouseSelectImage(e:MouseEvent) {
        selectedBox.top = Std.int(e.localY/tile_size.pos) * tile_size.pos;
        selectedBox.left = Std.int(e.localX/tile_size.pos) * tile_size.pos;
        selectedBox.width  = tile_size.pos * tile_width.pos;
        selectedBox.height = tile_size.pos * tile_height.pos;
        /*
        trace(e.localX);
        trace();*/
    }

    private function selectBox(x:Int, y:Int, width:Int, height:Int, add:Bool = true) {

        var b = add ? "box_selection" : "box_selected";
        for (c in findComponents(b, Component)) {

            var isX = false;
            var isY = false;

            for (i in x...x+width) {
                if (c.hasClass("x_"+i)) isX = true;
            }
            for (i in y...y+width) {
                if (c.hasClass("y_"+i)) isY = true;
            }

            if (isX && isY) {
                if (add) {
                    c.addClass("box_selected");
                    c.removeClass("box_selection");
                }
                else {
                    c.removeClass("box_selected");
                    c.addClass("box_selection");
                }
            }
            
        }
    }


    /*function tileHtml( v : cdb.Types.TilePos, ?isInline ) {
		var path = getAbsPath(v.file);
		if( !quickExists(path) ) {
			if( isInline ) return "";
			return '<span class="error">' + v.file + '</span>';
		}
		var id = UID++;
		var width = v.size * (v.width == null?1:v.width);
		var height = v.size * (v.height == null?1:v.height);
		var max = width > height ? width : height;
		var zoom = max <= 32 ? 2 : 64 / max;
		var inl = isInline ? 'display:inline-block;' : '';
		var url = "file://" + path;
		var html = '<div class="tile" id="_c${id}" style="width : ${Std.int(width * zoom)}px; height : ${Std.int(height * zoom)}px; background : url(\'$url\') -${Std.int(v.size*v.x*zoom)}px -${Std.int(v.size*v.y*zoom)}px; opacity:0; $inl"></div>';
		html += '<img src="$url" style="display:none" onload="$(\'#_c$id\').css({opacity:1, backgroundSize : ((this.width*$zoom)|0)+\'px \' + ((this.height*$zoom)|0)+\'px\' '+(zoom > 1 ? ", imageRendering : 'pixelated'" : "") +'}); if( this.parentNode != null ) this.parentNode.removeChild(this)"/>';
		return html;
	}*/
}