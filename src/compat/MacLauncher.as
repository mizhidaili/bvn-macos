package {
 import flash.display.Sprite;
 import flash.display.Loader;
 import flash.net.URLRequest;
 import flash.system.ApplicationDomain;
 import flash.system.LoaderContext;
 import net.play5d.game.bvn.win.utils.FileUtils;
 import net.play5d.game.bvn.win.utils.Loger;
 [SWF(width="800",height="600",frameRate="60",backgroundColor="#000000")]
 public class MacLauncher extends Sprite {
  public function MacLauncher(){
   Loger.ensureLinked();
   // Register adapter before the original packed game defines its file helper.
   var savePath:String=FileUtils.getAppFloderFileUrl('bvnsave.sav');
   trace('MAC_SAVE_PATH '+savePath);
   var loader:Loader=new Loader();addChild(loader);
   var context:LoaderContext=new LoaderContext(false,ApplicationDomain.currentDomain);
   context.allowCodeImport=true;loader.load(new URLRequest('launch.f'),context);
  }
 }
}
