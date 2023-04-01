/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.FullScreenEvent;
import flash.events.UncaughtErrorEvent;
import flash.external.ExternalInterface;
import flash.system.Security;

import mx.core.IVisualElement;
import mx.events.FlexEvent;

import spark.components.Alert;

import events.CustomEvent;

import me.whohacked.app.AppWideDebug_Singleton;
import me.whohacked.app.AppWideEventDispatcher_Singleton;
import me.whohacked.app.AppWide_Singleton;
import me.whohacked.app.IconManager_Singleton;



private var __appWideSingleton:AppWide_Singleton;
private var __appWideEventDispatcher:AppWideEventDispatcher_Singleton;

public var debugMode:Boolean;

// the ?prop1=var1&prop2=var2 query passed in the URL
public var flashVars:Object;



private function preinitializeHandler(event:FlexEvent):void
{
	//Security.allowDomain("*");
	
	__appWideSingleton = AppWide_Singleton.getInstance();
	__appWideEventDispatcher = AppWideEventDispatcher_Singleton.getInstance();
	
	this.debugMode = __appWideSingleton.appInfoObj.debugMode;
	
	event = null;
}


private function initializeHandler(event:FlexEvent):void
{
	if (ExternalInterface.available)
	{
		try {
			ExternalInterface.addCallback("resizeAppResult", resizeAppResult);
		} catch (e:Error) {
			// A problem occurred making the call
			debugMsg("setAppLayout->  ExternalInterface ERROR!");
		}
	} else {
		// No external interface available
		debugMsg("setAppLayout->  ExternalInterface ERROR!  NOT_AVAILABLE");
	}
	
	event = null;
}


private function applicationCompleteHandler(event:FlexEvent):void
{
	debugMsg("applicationCompleteHandler->  Application Complete!\tSWF version "+loaderInfo.swfVersion+"  browserMeasuredWidth: "+screen.width+"  browserMeasuredHeight: "+screen.height+"  stageWidth: "+stage.stageWidth+"  stageHeight: "+stage.stageHeight+"  stage.width: "+stage.width+"  stage.height: "+stage.height+"  width: "+this.width+"  height: "+this.height);
	
	// variables from the URL that loads this .swf
	__appWideSingleton.flashVars = {};// loaderInfo.parameters;
	flashVars = __appWideSingleton.flashVars;
	for (var i:String in flashVars) { debugMsg("flashVars.i: "+i+"  flashVars.info[i]: "+flashVars[i]); } i = null;
	
	// handle uncaught events
	/*if (this.loaderInfo)
		this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this._onUncaughtError);*/
	
	// listen for the RESIZE event
	this.stage.addEventListener(Event.RESIZE, stageResizeHandler, false,0,true);
	
	// listen for the FullScreen event
	this.stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenEventHandler, false,0,true);
	
	// listen for changes made by the LayoutManager singleton
	__appWideEventDispatcher.addEventListener("onLayoutChanged", onLayoutChanged, false,0,true);
	
	if ((flashVars.isPopout != null) && 
		(flashVars.isPopout != undefined) && 
		(flashVars.isPopout.toString() == "true"))
	{
		setAppLayout('100%', '100%', StageScaleMode.NO_BORDER);
	} else {
		setAppLayout(1160, 685,/* '100%', '100%',*/ StageScaleMode.SHOW_ALL);
	}
	
	tubBg_I.source = IconManager_Singleton.getInstance().getIcon('app_tubbg');
	
	//this.stage.frameRate = 30;
	
	debugMsg("applicationCompleteHandler->  frameRate: "+stage.frameRate+"  browserMeasuredWidth: "+screen.width+"  browserMeasuredHeight: "+screen.height+"  stageWidth: "+stage.stageWidth+"  stageHeight: "+stage.stageHeight+"  stage.width: "+stage.width+"  stage.height: "+stage.height+"  width: "+this.width+"  height: "+this.height+"  scaleMode: "+stage.scaleMode+"  allowsFullScreenInteractive: "+stage.allowsFullScreenInteractive);
	
	// listen for setUserID from the server, and call createLobby
	loginPanel.nc.client.addEventListener("createLobby", createLobby, false,0,true);
	
	__appWideEventDispatcher.dispatchEvent(new Event('onApplicationComplete'));
	
	event = null;
}


// create the Lobby when onSetUserID has been dispatched
private function createLobby(event:CustomEvent):void
{
	debugMsg("createLobby->  RECEIVED  userInfoObj: "+event.eventObj+"  clientID: "+event.eventObj.clientID+"  acctID: "+event.eventObj.acctID+"  userID: "+event.eventObj.userID);
	
	__appWideSingleton.userInfoObj.clientID = event.cloneCustomEvent().eventObj.clientID;
	__appWideSingleton.userInfoObj.acctID = event.cloneCustomEvent().eventObj.acctID;
	__appWideSingleton.userInfoObj.userID = event.cloneCustomEvent().eventObj.userID;
	__appWideSingleton.userInfoObj.userName = event.cloneCustomEvent().eventObj.userName;
	// the rest of the local clients info is added to __appWideSingleton.userInfoObj
	// after the UserList is initialised
	
	// change the state to chatState
	this.currentState = "chatState";
	
	/*
	// check the bandwidth to the server
	loginPanel.nc.call("checkBandwidth", null);
	
	// get the bandwidth limit from the server
	var responder:Responder = new Responder(getBandwidthLimitResponder);
	
	function getBandwidthLimitResponder(info:Object):void
	{
		debugMsg("getBandwidthLimitResponder->  " + info);
		for (var i:String in info) { trace(i + " - " + info[i]); }
	}
	
	loginPanel.nc.call("getBandwidthLimit", responder, 0);
	*/
	
	// connect and init the lobby and children....
	// init the mediaSO which controls users video/audio
	lobby.mediaManager.initMediaManager();
	
	// init the lobby
	lobby.initLobby();
	
	// get the list of blocked users
	//loginPanel.nc.call("getBlockedUsers", null, event.cloneCustomEvent().eventObj.clientID);
	
	// TODO: fix/move
	if (__appWideSingleton.userInfoObj.acctID!=0)
		__appWideEventDispatcher.dispatchEvent(new CustomEvent("onGetBlockedUsersListResult", false, false, event.cloneCustomEvent().eventObj.blockedUsersObj));
	
	applicationBar.applicationBar_blockList_Btn.enabled = true;
	
	// init the user list AFTER setting the blockedUsersList
	lobby.userListPanel.initUserList();
	
	// get the list of users
	//loginPanel.nc.call("getUserList", null, event.cloneCustomEvent().eventObj.clientID);
	
	// TODO: fix/move
	__appWideEventDispatcher.dispatchEvent(new CustomEvent("userList_onGetUserList", false, false, event.cloneCustomEvent().eventObj.userListObj));
	
	// start the stats timer
	if (!__appWideSingleton.statsTimer.running)
		__appWideSingleton.statsTimer.start();
	
	//responder = null;
	event = null;
}


private function callExternalMethod(method:String, obj:Object):void
{
	if (ExternalInterface.available)
	{
		try {
			// exec JS
			//ExternalInterface.call("eval", "document.close();"); 
			// call a JS function
			ExternalInterface.call(method, obj);
			// Invoke the get_cookie function, feeding it the "someParameter" String.
			//var returnedString:String = ExternalInterface.call("get_cookie", "someParameter")); 
		} catch (e:Error) {
			// A problem occurred making the call
			debugMsg("callExternalMethod->  ExternalInterface ERROR!");
		}
	} else {
		// No external interface available
		debugMsg("callExternalMethod->  ExternalInterface ERROR!  NOT_AVAILABLE");
	}
	
	obj = null;
	method = null;
}


public function resizeAppResult(infoObj:Object):void
{
	if (!this.stage) return;
	
	debugMsg("resizeAppResult->  browserMeasuredWidth: "+infoObj.browserMeasuredWidth+"  browserMeasuredHeight: "+infoObj.browserMeasuredHeight+"  stageWidth: "+stage.stageWidth+"  stageHeight: "+stage.stageHeight+"  stage.width: "+stage.width+"  stage.height: "+stage.height+"  width: "+this.width+"  height: "+this.height);
	
	for (var i:String in infoObj)
	{
		debugMsg("resizeAppResult->\t\tinfoObj:\t"+i+"	=	"+infoObj[i]);
	}
	/*
	if (ExternalInterface.available)
	{
		try {
			// remove the result listener
			ExternalInterface.addCallback('resizeAppResult', null);
		} catch (e:Error) {
			// A problem occurred making the call
			debugMsg("resizeAppResult->  ExternalInterface ERROR!");
		}
	} else {
		// No external interface available
		debugMsg("resizeAppResult->  ExternalInterface ERROR!  NOT_AVAILABLE");
	}
	*/
	if (this.stage.stageHeight > 0 && this.stage.stageWidth > 0)
	{
		//this.stage.removeEventListener(Event.RESIZE, resizeHandler); // only execute once
		
		this.stage.scaleMode = infoObj.scaleMode;
		
		//this.stage.width = infoObj.appWidth;
		//this.stage.height = infoObj.appHeight;
		this.stage.stageWidth = infoObj.appWidth;
		this.stage.stageHeight = infoObj.appHeight;
		this.width = infoObj.appWidth;
		this.height = infoObj.appHeight;
		
		//this.stage.stageWidth = this.width;
		//this.stage.stageHeight = this.height;
		//this.stage.width = this.stage.stageWidth;
		//this.stage.height = this.stage.stageHeight;
		//this.width = this.stage.stageWidth;
		//this.height = this.stage.stageHeight;
		
		var _browserScaling:Number = infoObj.browserMeasuredWidth / this.stage.stageWidth;
		
		debugMsg("resizeAppResult->  browserMeasuredWidth: "+infoObj.browserMeasuredWidth+
									"  browserMeasuredHeight: "+infoObj.browserMeasuredHeight+
									"  browserScaling: "+_browserScaling+
									"  scaleMode: "+stage.scaleMode+
									"  stageWidth: "+stage.stageWidth+
									"  stageHeight: "+stage.stageHeight+
									"  stage.width: "+stage.width+
									"  stage.height: "+stage.height+
									"  width: "+this.width+
									"  height: "+this.height);
	}
	
	infoObj = null;
}


private function stageResizeHandler(event:Event):void
{
	debugMsg("stageResizeHandler->  screenWidth: "+screen.width+"  screenHeight: "+screen.height+"  stageWidth: "+stage.stageWidth+"  stageHeight: "+stage.stageHeight+"  stage.width: "+stage.width+"  stage.height: "+stage.height+"  width: "+this.width+"  height: "+this.height);
	
	loginPanel.horizontalCenter = 0;
	
	__appWideEventDispatcher.dispatchEvent(new Event('onAppResize',false,false));
	
	event = null;
}


private function onFullScreenEventHandler(event:FullScreenEvent):void
{
	debugMsg("onFullScreenEventHandler->  fullscreen: "+event.fullScreen+"  screenWidth: "+screen.width+"  screenHeight: "+screen.height+"  stageWidth: "+stage.stageWidth+"  stageHeight: "+stage.stageHeight+"  stage.width: "+stage.width+"  stage.height: "+stage.height+"  width: "+this.width+"  height: "+this.height);
	
	event = null;
}


// swap the DisplayObject to the top most child (Element)
private function bringComponentToTop(event:CustomEvent):void
{
	this.swapElementsAt(this.getElementIndex(event.eventObj as IVisualElement), this.numElements - 1);
	
	event = null;
}


private function setAppLayout(newWidth:*=1160, newHeight:*=685, newScaleMode:String="showAll", defaultBGColor:String="#393939", defaultAppBGColor:String="#333333"):void
{
	debugMsg("setAppLayout->  newWidth: "+newWidth+"  newHeight: "+newHeight+"  newScaleMode: "+newScaleMode+"  defaultBGColor: "+defaultBGColor+"  defaultAppBGColor: "+defaultAppBGColor);
	
	callExternalMethod('resizeApp', {layoutName:"default_"+newWidth+"x"+newHeight, width:newWidth, height:newHeight, scaleMode:newScaleMode, bgcolor:defaultBGColor, appbgcolor:defaultAppBGColor});
}


private function onLayoutChanged(event:CustomEvent):void
{
	debugMsg("onLayoutChanged->  layoutName: "+event.eventObj.layoutName);
	
	var selectedLayoutObj:Object = event.eventObj;
	
	// update 'this.width/height' after resizing
	//if (this.width != selectedLayoutObj.width || this.height != selectedLayoutObj.height)
	//{
	//	this.width = selectedLayoutObj.width;
	//	this.height = selectedLayoutObj.height;
	//}
	
	//if (__appWideSingleton.appInfoObj.debugMode)
	//{
	//	Alert.show("isPopout = "+__flashVars.isPopout+'\n\n'+'ScaleMode = '+this.stage.scaleMode+'\n\n'+'selectedLayout = '+selectedLayoutObj.layoutName+'\n'+'height = '+selectedLayoutObj.height+'\n'+'width = '+selectedLayoutObj.width);
	//}
	
	selectedLayoutObj = null;
	event = null;
}












// TEMP DISABLED
private function _onUncaughtError(event:UncaughtErrorEvent):void
{
	// do something here with e.error (can be an Error or ErrorEvent), like log 
	// the error, perhaps even going crazy and using the RuntimeErrorUtil class
	event.preventDefault(); // stops the error dialog box showing up
	
	Alert.show("An unknown error occurred!\n\n" +
				"If this keeps happening, " +
				"please try to reproduce this error and tell the administrator.\n\n\n"/* +
				"Error: " + event*/);
	
	event = null;
}






private function debugMsg(str:String):void
{
	AppWideDebug_Singleton.getInstance().newDebugMessage(this.id, str);
	str = null;
}

