package {
 import flash.display.Sprite;
 import flash.desktop.NativeApplication;
 import flash.filesystem.*;
 import flash.text.*;
 import net.play5d.game.bvn.win.utils.FileUtils;
 import net.play5d.game.bvn.win.utils.Loger;
 [SWF(width="700",height="240",frameRate="1")]
 public class StorageAdapterTest extends Sprite {
  private var checks:Array=[];
  private function check(ok:Boolean,name:String):void {checks.push({name:name,pass:ok});if(!ok)throw new Error(name);}
  public function StorageAdapterTest(){
   var result:Object={pass:false,checks:checks};
   try{
    var seed:File=File.applicationDirectory.resolvePath('bvnsave.sav');
    var seedText:String=seed.exists?FileUtils.readTextFile(seed.nativePath):null;
    var target:String=FileUtils.getAppFloderFileUrl('bvnsave.sav');
    check(target.indexOf(File.applicationStorageDirectory.nativePath)==0,'save is outside app package');
    check(FileUtils.readTextFile(target)==seedText,'seed copied or absent seed remains absent');
    FileUtils.writeAppFloderFile('bvnsave.sav','{"revision":2}');
    check(JSON.parse(FileUtils.readTextFile(target)).revision==2,'write persisted');
    check(FileUtils.getAppFloderFileUrl('bvnsave.sav')==target&&JSON.parse(FileUtils.readTextFile(target)).revision==2,'existing save not reseeded');
    FileUtils.writeAppFloderFile('bvnsave.sav','{"revision":3}');
    check(JSON.parse(FileUtils.readTextFile(target+'.previous')).revision==2,'previous valid save retained');
    var rejected:Boolean=false;
    try{FileUtils.writeAppFloderFile('bvnsave.sav','{broken');}catch(expected:Error){rejected=true;}
    check(rejected&&JSON.parse(FileUtils.readTextFile(target)).revision==3,'invalid write preserves valid save');
    check((seed.exists?FileUtils.readTextFile(seed.nativePath):null)==seedText,'bundled seed unchanged');
    var logger:Loger=new Loger();logger.log('storage-adapter-test');
    check(FileUtils.readTextFile(File.applicationStorageDirectory.resolvePath('runtime.log').nativePath).indexOf('storage-adapter-test')>=0,'logger outside bundle');
    check(!File.applicationDirectory.resolvePath('log.log').exists,'no original package log created');
    result.pass=true;
   }catch(error:Error){result.error=error.toString();}
   var report:FileStream=new FileStream();report.open(File.applicationStorageDirectory.resolvePath('test-result.json'),FileMode.WRITE);report.writeUTFBytes(JSON.stringify(result));report.close();
   trace('STORAGE_TEST '+JSON.stringify(result));
   var text:TextField=new TextField();text.width=690;text.height=230;text.multiline=true;text.wordWrap=true;text.defaultTextFormat=new TextFormat('_sans',16,result.pass?0x167537:0xb00020);text.text=(result.pass?'PASS':'FAIL')+' — storage adapter\n'+JSON.stringify(result);addChild(text);
   NativeApplication.nativeApplication.exit(result.pass?0:1);
  }
 }
}
