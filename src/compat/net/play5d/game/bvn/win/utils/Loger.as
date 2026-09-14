package net.play5d.game.bvn.win.utils {
 import flash.filesystem.*;
 import net.play5d.game.bvn.interfaces.ILoger;
 // Keep original logger API while writing outside the signed application bundle.
 public class Loger implements ILoger {
  public static const ENABLED:Boolean=false;
  private static var started:Boolean=false;
  private static var callback:Function;
  public static function ensureLinked():void {}
  public function setLogCall(fn:Function):void {callback=fn;}
  public function log(message:String):void {
   if(callback!=null)callback(message);
   var file:File=File.applicationStorageDirectory.resolvePath('runtime.log');
   var stream:FileStream=new FileStream();
   try{
    File.applicationStorageDirectory.createDirectory();
    stream.open(file,started?FileMode.APPEND:FileMode.WRITE);
    stream.writeUTFBytes(message+'\n');stream.close();started=true;
   }catch(error:Error){trace('MAC_LOG_ERROR '+error.toString());}
  }
 }
}
