package net.play5d.game.bvn.win.utils {
 import flash.filesystem.File;
 import flash.filesystem.FileMode;
 import flash.filesystem.FileStream;
 import flash.utils.ByteArray;
 // API-compatible local storage adapter. The original game payload is unchanged.
 public class FileUtils {
  public static function getAppFloderFileUrl(name:String):String {
   if(name!='bvnsave.sav')return File.applicationDirectory.resolvePath(name).nativePath;
   var destination:File=File.applicationStorageDirectory.resolvePath(name);
   if(!destination.exists){
    File.applicationStorageDirectory.createDirectory();
    var seed:File=File.applicationDirectory.resolvePath(name);
    // Plain stream copy avoids the native clonefile path observed stalling
    // when importing a seed from a sealed, ad-hoc signed application bundle.
    if(seed.exists)writeFile(destination.nativePath,readTextFile(seed.nativePath));
   }
   return destination.nativePath;
  }
  public static function writeAppFloderFile(name:String,data:*,mode:String=null):void {
   if(name=='bvnsave.sav'&&(!mode||mode==FileMode.WRITE)){
    // Validate before touching the previous save; retain one recovery copy.
    var encoded:String=String(data);JSON.parse(encoded);
    var target:File=new File(getAppFloderFileUrl(name));
    var temporary:File=File.applicationStorageDirectory.resolvePath(name+'.pending');
    writeFile(temporary.nativePath,encoded,FileMode.WRITE);
    if(target.exists)writeFile(File.applicationStorageDirectory.resolvePath(name+'.previous').nativePath,readTextFile(target.nativePath));
    temporary.moveTo(target,true);
    return;
   }
   writeFile(getAppFloderFileUrl(name),data,mode);
  }
  public static function writeFile(path:String,data:*,mode:String=null):void {
   var stream:FileStream=new FileStream();
   try {
    stream.open(new File(path),mode||FileMode.WRITE);
    if(data is ByteArray)stream.writeBytes(data,0,data.length);
    else stream.writeUTFBytes(String(data));
   } finally {stream.close();}
  }
  public static function readTextFile(path:String):String {
   var file:File=new File(path);if(!file.exists)return null;
   var stream:FileStream=new FileStream();
   var result:String;
   try{stream.open(file,FileMode.READ);result=stream.readUTFBytes(stream.bytesAvailable);}
   finally{stream.close();}
   return result;
  }
  public static function createFloder(path:String):void {new File(path).createDirectory();}
  public static function del(path:String):void {var file:File=new File(path);if(file.exists)file.deleteFile();}
 }
}
