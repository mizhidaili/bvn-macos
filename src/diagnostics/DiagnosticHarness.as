package {
 import flash.display.*;
 import flash.events.*;
 import flash.net.URLRequest;
 import flash.system.*;
 import flash.text.*;
 import flash.utils.*;
 [SWF(width="800",height="700",frameRate="60",backgroundColor="#14202b")]
 public class DiagnosticHarness extends Sprite {
  private var loader:Loader=new Loader();
  private var panel:Sprite=new Sprite();
  private var status:TextField=new TextField();
  private var jobs:Array=[];
  private var ticks:int=0;
  private var lastError:String='';
  public function DiagnosticHarness() {
   addChild(loader);addChild(panel);
   panel.graphics.beginFill(0x14202b);panel.graphics.drawRect(0,600,800,100);panel.graphics.endFill();
   var labels:Array=['A 500','D 500','K 150','J 150','U 150','W+J','S+J','S+U','W+I','S+I','O 150','Esc'];
   var keys:Array=[[65],[68],[75],[74],[85],[87,74],[83,74],[83,85],[87,73],[83,73],[79],[27]];
   for(var i:int=0;i<labels.length;i++) button(String(labels[i]),8+(i%6)*132,604+int(i/6)*30,keys[i],i<2?500:150);
   status.width=795;status.height=28;status.x=5;status.y=668;status.defaultTextFormat=new TextFormat('_sans',12,0xffffff);
   status.text='DIAGNOSTIC ONLY — in-app synthetic input; physical keyboard unverified';panel.addChild(status);
   var context:LoaderContext=new LoaderContext(false,ApplicationDomain.currentDomain);context.allowCodeImport=true;
   loader.load(new URLRequest('launch.f'),context);
   addEventListener(Event.ENTER_FRAME,frame);
  }
  private function button(label:String,xp:int,yp:int,keys:Array,duration:int):void {
   var b:Sprite=new Sprite();b.graphics.beginFill(0x416a85);b.graphics.drawRoundRect(0,0,124,25,4);b.graphics.endFill();b.x=xp;b.y=yp;b.buttonMode=true;
   var t:TextField=new TextField();t.defaultTextFormat=new TextFormat('_sans',13,0xffffff);t.text=label;t.width=120;t.height=24;t.mouseEnabled=false;b.addChild(t);panel.addChild(b);
   b.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void { runKeys(label,keys,duration); });
  }
  private function runKeys(label:String,keys:Array,duration:int):void {
   release();stage.focus=stage;
   trace('DIAG_INPUT '+JSON.stringify({time:getTimer(),name:label,keys:keys,duration:duration,source:'in-app test control'}));
   for each(var k:int in keys) stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,k,k));
   jobs.push({keys:keys,end:getTimer()+duration});status.text='SCRIPTED '+label+'; physical keyboard unverified';
  }
  private function release():void {
   for each(var j:Object in jobs) for each(var k:int in j.keys) stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,k,k));
   jobs=[];
  }
  private function frame(e:Event):void {
   if(panel.parent && getChildIndex(panel)!=numChildren-1)setChildIndex(panel,numChildren-1);
   if(jobs.length && getTimer()>=jobs[0].end)release();
   if(++ticks%15!=0)return;
   try {
    var gc:Class=getDefinitionByName('net.play5d.game.bvn.ctrl.game_ctrls.GameCtrl') as Class;
    if(!gc.I.gameState)return;
    var out:Array=[];
    for each(var f:Object in gc.I.gameState.getGameSprites()) {
     if(!('data' in f)||!f.data)continue;
     var item:Object={id:f.data.id,hp:f.hp,x:f.x,y:f.y};
     if('qi' in f){item.qi=f.qi;item.energy=f.energy;item.state=f.actionState;}
     try {item.label=f.getMC().getCurrentLabel();item.frame=f.getMC().getCurrentFrame();}catch(ignore:Error){}
     out.push(item);
    }
    trace('DIAG_STATE '+JSON.stringify({time:getTimer(),stageFPS:stage.frameRate,active:gc.I.actionEnable,fighters:out}));
   } catch(ignore2:Error) {if(ignore2.toString()!=lastError){lastError=ignore2.toString();trace('DIAG_LOOKUP '+lastError);}}
  }
 }
}
