package {
 import flash.display.*;
 import flash.events.*;
 import flash.filesystem.*;
 import flash.net.URLRequest;
 import flash.system.*;
 import flash.media.SoundMixer;
 import flash.text.*;
 import flash.utils.*;
 import net.play5d.game.bvn.win.utils.FileUtils;
 import net.play5d.game.bvn.win.utils.Loger;
 [SWF(width="800",height="700",frameRate="60",backgroundColor="#14202b")]
 public class SuiteHarness extends Sprite {
  private var loader:Loader=new Loader();
  private var panel:Sprite=new Sprite();
  private var status:TextField=new TextField();
  private var report:FileStream=new FileStream();
  private var cases:Array=[];
  private var index:int=-1;
  private var phase:String='idle';
  private var since:int=0;
  private var battleStart:int=0;
  private var lastFrame:int=0;
  private var previousState:String='';
  private var pressed:Object={};
  private var releases:Array=[];
  private var steps:Array=[];
  private var stats:Object;
  private var sampling:int=0;
  private var activeMillis:int=0;
  private var launchStarted:Boolean=false;
  private var approachUntil:int=0;
  private var approachPlayer:int=0;
  private var menuOpened:Boolean=false;
  private var audioSamples:ByteArray=new ByteArray();
  private var stepTemplate:Array=[];
  private var cues:Array=[];
  private var nextRepeat:int=0;
  private var lastLoadingConfirm:int=0;
  private var nextMosouInput:int=0;
  private var postgameClicked:Boolean=false;
  private var assistObjects:Dictionary=new Dictionary(true);
  public function SuiteHarness(){
   Loger.ensureLinked();
   FileUtils.getAppFloderFileUrl('bvnsave.sav');
   var stream:FileStream=new FileStream();stream.open(File.applicationDirectory.resolvePath('suite.json'),FileMode.READ);
   cases=JSON.parse(stream.readUTFBytes(stream.bytesAvailable)) as Array;stream.close();
   var folder:File=File.applicationStorageDirectory.resolvePath('diagnostics');folder.createDirectory();
   var output:File=folder.resolvePath('suite-'+new Date().time+'.jsonl');report.open(output,FileMode.WRITE);
   trace('SUITE_REPORT '+output.nativePath);
   addChild(loader);addChild(panel);panel.graphics.beginFill(0x14202b);panel.graphics.drawRect(0,600,800,100);panel.graphics.endFill();
   button('START SUITE',10,start);button('STOP',150,stop);button('INSPECT UI',290,inspectUI);button('J 150ms',430,function():void{keys([74],150);});
   status.defaultTextFormat=new TextFormat('_sans',12,0xffffff);status.x=10;status.y=642;status.width=780;status.height=55;status.multiline=true;
   status.text='INTEGRATION TEST — synthetic AIR input, original game code. Physical keyboard unverified.';panel.addChild(status);
   var context:LoaderContext=new LoaderContext(false,ApplicationDomain.currentDomain);context.allowCodeImport=true;loader.load(new URLRequest('launch.f'),context);
   addEventListener(Event.ENTER_FRAME,tick);
  }
  private function cls(name:String):Class{return getDefinitionByName('net.play5d.game.bvn.'+name) as Class;}
  private function button(label:String,xp:int,fn:Function):void{
   var b:Sprite=new Sprite();b.x=xp;b.y=607;b.graphics.beginFill(0x416a85);b.graphics.drawRect(0,0,125,27);b.graphics.endFill();b.buttonMode=true;
   var t:TextField=new TextField();t.defaultTextFormat=new TextFormat('_sans',13,0xffffff);t.text=label;t.width=124;t.height=25;t.mouseEnabled=false;b.addChild(t);panel.addChild(b);
   b.addEventListener(MouseEvent.CLICK,function(e:MouseEvent):void{fn();});
  }

  private function selectionOf(s:Object):Object{return s?{fighter1:s.fighter1,fighter2:s.fighter2,fighter3:s.fighter3,assist:s.fuzhu}:null;}
  private function inspectUI():void{
   try{
    var gd:Object=cls('data.GameData').I;var gc:Object=cls('ctrl.game_ctrls.GameCtrl').I;
    var info:Object={stage:getQualifiedClassName(cls('MainGame').stageCtrl.currentStage),mode:cls('data.GameMode').currentMode,p1:selectionOf(gd.p1Select),p2:selectionOf(gd.p2Select),selectedMap:gd.selectMap,savePath:cls('win.utils.FileUtils').getAppFloderFileUrl('bvnsave.sav')};
    if(gc.gameState){info.map=gc.gameRunData.map.id;var fighters:Array=getFighters();info.fighters=[];for each(var f:Object in fighters)info.fighters.push(stateOf(f));}
    log('ui_inspection',info);status.text='UI state recorded — '+info.stage+'; synthetic test controls are separate from physical keyboard';
   }catch(error:Error){log('ui_inspection_error',{error:error.toString()});}
  }
  private function log(type:String,data:Object):void{data.type=type;data.time=getTimer();var s:String=JSON.stringify(data);trace('SUITE '+s);report.writeUTFBytes(s+'\n');}
  private function start():void{
   if(phase!='idle')return;
   try{launchStarted=true;next();}catch(e:Error){log('start_error',{error:e.toString()});}
  }
  private function stop():void{releaseAll();phase='stopped';status.text='STOPPED — see suite report';log('stop',{index:index,activeMillis:activeMillis});}
  private function releaseAll():void{for(var key:String in pressed)stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,int(key),int(key)));pressed={};releases=[];}
  private function keys(k:Array,duration:int):void{
   for each(var key:int in k){stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,key,key));pressed[String(key)]=true;}
   releases.push({at:getTimer()+duration,keys:k});log('input',{index:index,keys:k,duration:duration});
  }
  private function next():void{
   releaseAll();index++;if(index>=cases.length){phase='done';status.text='SUITE DONE — '+cases.length+' cases; physical keyboard unverified';log('done',{cases:cases.length,activeMillis:activeMillis});return;}
   phase='transition';since=getTimer();battleStart=0;approachUntil=0;menuOpened=false;
   if(index>0)cls('MainGame').I.goMenu();
   stats={config:cases[index],loaded:false,labels:{},p2labels:{},minHP:999999,minEnemyHP:999999,minQi:999999,maxQi:0,minEnergy:999999,maxX:-999999,minX:999999,minY:999999,frames:0,gapsOver250:0,maxFrameGap:0,audioPeak:0,assistSeen:false};
   log('case_start',{index:index,config:cases[index]});status.text='Case '+(index+1)+'/'+cases.length+' '+JSON.stringify(cases[index])+'\nSynthetic input; no physical-keyboard claim';
  }
  private function loadCase():void{
   var c:Object=cases[index];var gd:Object=cls('data.GameData').I;var Select:Class=cls('data.SelectVO');
   var p1:Object=new Select();p1.fighter1=c.fighter;p1.fuzhu=c.assist||'itachi';
   var p2:Object=new Select();p2.fighter1=c.enemy||'ichigo';p2.fuzhu='kon';
   p1.fighter2=c.fighter2||null;p1.fighter3=c.fighter3||null;
   p2.fighter2=c.enemy2||null;p2.fighter3=c.enemy3||null;
   gd.p1Select=p1;gd.p2Select=p2;gd.selectMap=c.map||'gense';
   gd.config.AI_level=c.ai||2;gd.config.fighterHP=1;gd.config.fightTime=c.fightTime||60;gd.config.applyConfig();
   cls('data.GameMode').currentMode=c.mode||22;
   if(c.mode==10||c.mode==20){cls('data.MessionModel').I.reset();cls('data.MessionModel').I.initMession();}
   if(c.mode==100){
    phase='mosou_config';since=getTimer();
    cls('data.mosou.MosouModel').I.loadMapData(function():void{
     var model:Object=cls('data.mosou.MosouModel').I;
     model.currentArea=model.getMapArea('map1',String(c.area));model.currentMission=model.currentArea.missions[int(c.missionIndex||0)];
     gd.mosouData.getCurrentMap().openArea(String(c.area));gd.mosouData.setCurrentArea(String(c.area));
     if(c.playerLevel){for each(var teamMember:Object in gd.mosouData.getFighterTeam())teamMember.readSaveObj({id:teamMember.id,level:int(c.playerLevel),exp:0});log('level_fixture',{index:index,level:c.playerLevel,scope:'isolated test profile for NPC resource coverage; not original progress or ordinary-play validation'});}
     log('mission_fixture',{index:index,area:c.area,mission:model.currentMission.id,scope:'test opens/selects an existing area and mission in this isolated save; no ordinary unlock/progression claim'});
     cls('MainGame').I.loadGame();phase='loading';since=getTimer();
    },function():void{finish('mosou_config_load_failed');});return;
   }
   cls('MainGame').I.loadGame();phase='loading';since=getTimer();lastLoadingConfirm=since;
  }
  private function getFighters():Array{
   var gc:Object=cls('ctrl.game_ctrls.GameCtrl').I;var out:Array=[];if(!gc.gameState)return out;
   // Grabs temporarily remove actors from the display collection. The team's
   // current fighter remains the authoritative actor during those animations.
   var a:Object=gc.gameRunData.p1FighterGroup.currentFighter;
   var b:Object=gc.gameRunData.p2FighterGroup.currentFighter;
   if(a&&b){out.push(a);out.push(b);}
   return out;
  }
  private function stateOf(f:Object):Object{
   var h:Object=f.getLastHurtHitVO();
   return {id:f.data.id,hp:f.hp,qi:f.qi,energy:f.energy,fzqi:f.fzqi,x:f.x,y:f.y,state:f.actionState,label:f.getMC().getCurrentLabel(),frame:f.getMC().getCurrentFrame(),rootFrame:f.mc.currentFrame,allowBeHit:f.isAllowBeHit,cross:f.isCross,lastHurt:h?{id:h.id,power:h.power,damage:h.getDamage()}:null};
  }
  private function beginBattle():void{
   assistObjects=new Dictionary(true);stats.assistObjectCount=0;
   phase='battle';battleStart=getTimer();stats.loaded=true;lastFrame=battleStart;previousState='';
   steps=[{at:300,approach:1},{at:1700,keys:[97],duration:120},{at:2600,keys:[74],duration:100},{at:3200,keys:[74],duration:100},{at:3800,keys:[74],duration:100},{at:4800,keys:[85],duration:100},{at:6000,approach:1},{at:7500,keys:[87,74],duration:100},{at:9300,keys:[83,74],duration:100},{at:11500,keys:[75],duration:100},{at:11800,keys:[74],duration:100},{at:14000,keys:[79],duration:100},{at:17000,keys:[87,85],duration:100},{at:20500,keys:[76],duration:150},{at:22500,keys:[73],duration:100},{at:27500,keys:[83,85],duration:100},{at:30000,approach:2},{at:31500,keys:[97],duration:120},{at:32100,keys:[97],duration:120},{at:34000,keys:[87,73],duration:100}];
   if(cases[index].steps)steps=JSON.parse(JSON.stringify(cases[index].steps)) as Array;
   if(cases[index].watchOnly)steps=[];
   stepTemplate=JSON.parse(JSON.stringify(steps)) as Array;nextRepeat=int(cases[index].repeatEvery||0);
   cues=cases[index].cues?(JSON.parse(JSON.stringify(cases[index].cues)) as Array):[];
   var fixture:Object=cases[index].fixture;
   if(fixture){
    var actors:Array=getFighters();
    if('p1Qi' in fixture)actors[0].qi=fixture.p1Qi;
    if('p2Qi' in fixture)actors[1].qi=fixture.p2Qi;
    if('p1X' in fixture)actors[0].x=fixture.p1X;
    if('p2X' in fixture)actors[1].x=fixture.p2X;
    log('fixture_setup',{index:index,fixture:fixture,scope:'test-only initial in-memory state; not ordinary-play evidence'});
   }
   stats.rounds=1;stats.p1Wins=0;stats.p2Wins=0;stats.fightFinished=false;stats.ids={};
   log('battle_ready',{index:index});
  }
  private function finish(reason:String):void{
   releaseAll();stats.returnStage=getQualifiedClassName(cls('MainGame').stageCtrl.currentStage);stats.reason=reason;stats.battleMillis=battleStart?getTimer()-battleStart:0;log('case_result',{index:index,result:stats});phase='finishing';since=getTimer();
  }


  private function clickNamed(name:String,root:DisplayObjectContainer):Boolean{
   if(!root)return false;
   for(var ci:int=0;ci<root.numChildren;ci++){
    var child:DisplayObject=root.getChildAt(ci);if(!child||!child.visible||child.alpha<0.1)continue;
    if(child.name==name&&child.hasEventListener(MouseEvent.CLICK)){
     log('ui_click',{index:index,name:name,displayType:getQualifiedClassName(child)});
     child.dispatchEvent(new MouseEvent(MouseEvent.CLICK,true));return true;
    }
    if(child is DisplayObjectContainer&&clickNamed(name,child as DisplayObjectContainer))return true;
   }
   return false;
  }
  private function tickMosou(gc:Object,now:int):void{
   var stageName:String=getQualifiedClassName(cls('MainGame').stageCtrl.currentStage);
   if(stageName.indexOf('WorldMapState')>=0){stats.fightFinished=true;finish('mosou_finished_and_returned');return;}
   if(!gc.gameState)return;
   var fighter:Object=gc.gameRunData.p1FighterGroup.currentFighter;if(!fighter)return;
   var a:Object=stateOf(fighter);var nearest:Object=null;var distance:Number=999999;var snapshots:Array=[];
   for each(var obj:Object in gc.gameState.getGameSprites()){
    if(!('qi' in obj)||!('getMC' in obj)||!obj.data||obj==fighter)continue;
    var b:Object=stateOf(obj);snapshots.push(b);
    if(!stats.npcs[b.id])stats.npcs[b.id]={initialHP:b.hp,minHP:b.hp,labels:{},frames:0};
    var n:Object=stats.npcs[b.id];n.minHP=Math.min(n.minHP,b.hp);n.labels[b.label]=true;n.frames++;
    if(b.hp>0&&Math.abs(b.x-a.x)<distance){nearest=b;distance=Math.abs(b.x-a.x);}
   }
   var gap:int=now-lastFrame;lastFrame=now;stats.frames++;stats.maxFrameGap=Math.max(stats.maxFrameGap,gap);if(gap>250)stats.gapsOver250++;
   if(gc.actionEnable)activeMillis+=Math.min(gap,1000);
   stats.minHP=Math.min(stats.minHP,a.hp);stats.minQi=Math.min(stats.minQi,a.qi);stats.maxQi=Math.max(stats.maxQi,a.qi);stats.labels[a.label]=true;
   var ctrl:Object=gc.getMosouCtrl();stats.currentWave=ctrl.currentWave;stats.waveCount=ctrl.waveCount;stats.missionEnded=ctrl.getGameFinished();
   if(++sampling%12==0)log('mosou_state',{index:index,a:a,enemies:snapshots,active:gc.actionEnable,wave:ctrl.currentWave,missionEnded:stats.missionEnded});
   var elapsed:int=now-battleStart;
   if(gc.actionEnable&&nearest&&elapsed>=nextMosouInput){
    releaseAll();
    if(distance>80)keys([nearest.x>a.x?68:65],500);
    else{
     var cycle:int=int(elapsed/800)%8;
     if(cycle==0&&a.qi>=100)keys([87,73],100);
     else if(cycle==1)keys([85],100);
     else if(cycle==3)keys([87,74],100);
     else if(cycle==5)keys([83,74],100);
     else keys([74],100);
    }
    nextMosouInput=elapsed+800;
   }
   if(elapsed>=Number(cases[index].duration||370000))finish('mosou_duration_complete');
  }
  private function tick(e:Event):void{
   if(getChildIndex(panel)!=numChildren-1)setChildIndex(panel,numChildren-1);
   var now:int=getTimer();
   for(var i:int=releases.length-1;i>=0;i--){var job:Object=releases[i];if(now>=job.at){for each(var k:int in job.keys){stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,k,k));delete pressed[String(k)];}releases.splice(i,1);}}
   if(!launchStarted||phase=='done'||phase=='stopped')return;
   try{
    if(phase=='transition'){
     // The original title unregisters its render callback only when its menu
     // is opened. Follow that step before leaving, rather than bypassing it.
     if(!menuOpened&&now-since>800){keys([74],150);menuOpened=true;}
     if(now-since>2300){loadCase();return;}
    }
    if(phase=='finishing'&&now-since>1000){next();return;}
    if(phase=='postgame'){
     var returned:String=getQualifiedClassName(cls('MainGame').stageCtrl.currentStage);
     if(returned.indexOf('SelectFighterStage')>=0){finish('match_finished_continue_selected_and_returned');return;}
     if(!postgameClicked&&now-since>1500)postgameClicked=clickNamed('btn_yes',loader);
     if(now-since>25000)finish('postgame_return_timeout');return;
    }
    var gc:Object=cls('ctrl.game_ctrls.GameCtrl').I;
    if(phase=='loading'){
     if(cases[index].mode==100&&gc.gameState&&gc.actionEnable&&gc.gameRunData.p1FighterGroup.currentFighter){
      phase='battle';battleStart=getTimer();lastFrame=battleStart;nextMosouInput=0;stats.loaded=true;stats.npcs={};log('battle_ready',{index:index});return;
     }
     if(cases[index].mode!=100&&gc.gameState&&gc.actionEnable&&getFighters().length>=2){beginBattle();return;}
     if(cases[index].confirmOrder&&now-since>5000&&now-lastLoadingConfirm>1000){keys([74,97],100);lastLoadingConfirm=now;}
     if(now-since>35000){finish('load_timeout');return;}
    }
    if(phase=='mosou_config'&&now-since>35000){finish('mosou_config_timeout');return;}
    if(phase!='battle')return;
    if(cases[index].mode==100){tickMosou(gc,now);return;}
    var elapsed:int=now-battleStart;
    if(gc.fightFinished){
     stats.fightFinished=true;
     if(cases[index].returnViaContinue){releaseAll();phase='postgame';since=now;postgameClicked=false;log('postgame',{index:index,stage:getQualifiedClassName(cls('MainGame').stageCtrl.currentStage)});return;}
     finish('match_finished_and_returned');return;
    }
    var actors:Array=getFighters();
    if(actors.length<2){stats.fightFinished=gc.fightFinished;finish(gc.fightFinished?'match_finished_and_returned':'left_battle');return;}
    var a:Object=stateOf(actors[0]);var b:Object=stateOf(actors[1]);
    var signature:String=JSON.stringify([a.label,a.state,a.rootFrame,a.hp,a.qi,a.allowBeHit,a.cross,b.label,b.state,b.hp]);
    if(signature!=previousState){log('transition',{index:index,renderFrame:stats.frames,a:a,b:b});previousState=signature;}
    stats.rounds=Math.max(stats.rounds,gc.gameRunData.round);stats.p1Wins=gc.gameRunData.p1Wins;stats.p2Wins=gc.gameRunData.p2Wins;stats.fightFinished=gc.fightFinished;stats.ids[a.id]=true;
    var gap:int=now-lastFrame;lastFrame=now;stats.frames++;stats.maxFrameGap=Math.max(stats.maxFrameGap,gap);if(gap>250)stats.gapsOver250++;
    if(gc.actionEnable)activeMillis+=Math.min(gap,1000);
    stats.labels[a.label]=true;stats.p2labels[b.label]=true;stats.minHP=Math.min(stats.minHP,a.hp);stats.minEnemyHP=Math.min(stats.minEnemyHP,b.hp);stats.minQi=Math.min(stats.minQi,a.qi);stats.maxQi=Math.max(stats.maxQi,a.qi);stats.minEnergy=Math.min(stats.minEnergy,a.energy);stats.minX=Math.min(stats.minX,a.x);stats.maxX=Math.max(stats.maxX,a.x);stats.minY=Math.min(stats.minY,a.y);
    for each(var sprite:Object in gc.gameState.getGameSprites())if('data' in sprite&&sprite.data&&String(sprite.data.id)==String(cases[index].assist)&&!('qi' in sprite)){
     stats.assistSeen=true;
     if(!assistObjects[sprite]){assistObjects[sprite]=true;stats.assistObjectCount++;log('assist_observed',{index:index,id:sprite.data.id,count:stats.assistObjectCount});}
    }
    if(++sampling%6==0){
     try{SoundMixer.computeSpectrum(audioSamples,false,0);while(audioSamples.bytesAvailable)stats.audioPeak=Math.max(stats.audioPeak,Math.abs(audioSamples.readFloat()));}catch(audioError:Error){stats.audioError=audioError.toString();}
     log('state',{index:index,active:gc.actionEnable,a:a,b:b});
    }
    if(approachUntil>0){
     var dx:Number=approachPlayer==1?b.x-a.x:a.x-b.x;
     if(now>=approachUntil||Math.abs(dx)<=28){releaseAll();approachUntil=0;}
    }
    for each(var cue:Object in cues){
     var observed:Object=cue.actor==2?b:a;
     if(!cue.fired&&observed.frame==cue.frame){cue.fired=true;log('frame_cue',{index:index,cue:cue,observed:observed});keys(cue.keys,cue.duration||100);}
    }
    if(nextRepeat>0&&elapsed>=nextRepeat&&steps.length==0){
     steps=JSON.parse(JSON.stringify(stepTemplate)) as Array;for each(var repeatStep:Object in steps)repeatStep.at+=nextRepeat;
     nextRepeat+=int(cases[index].repeatEvery);
    }
    if(steps.length&&(gc.actionEnable||steps[0].ui)&&elapsed>=steps[0].at){
     var step:Object=steps.shift();
     if(step.approach){
      releaseAll();approachPlayer=step.approach;approachUntil=now+1200;
      var delta:Number=approachPlayer==1?b.x-a.x:a.x-b.x;
      keys([approachPlayer==1?(delta>0?68:65):(delta>0?39:37)],1200);
     }else if(step.clickName){if(!clickNamed(step.clickName,loader))log('ui_click_missing',{index:index,name:step.clickName});}
     else keys(step.keys,step.duration);
    }
    if(elapsed>=Number(cases[index].duration||40000)){finish('duration_complete');return;}
   }catch(error:Error){log('error',{index:index,phase:phase,error:error.toString(),stack:error.getStackTrace()});stop();}
  }
 }
}
