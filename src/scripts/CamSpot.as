import flash.events.AsyncErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.NetStatusEvent;
import flash.events.SampleDataEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TimerEvent;
import flash.media.SoundTransform;
import flash.media.Video;
import flash.net.NetStream;
import flash.utils.Timer;

import mx.collections.ArrayCollection;
import mx.core.DragSource;
import mx.core.IUIComponent;
import mx.core.UIComponent;
import mx.events.DragEvent;
import mx.events.FlexEvent;
import mx.managers.DragManager;
import mx.utils.ObjectUtil;
import mx.utils.StringUtil;

import events.CustomEvent;

import me.whohacked.app.AppWideDebug_Singleton;
import me.whohacked.app.AppWideEventDispatcher_Singleton;
import me.whohacked.app.AppWide_Singleton;
import me.whohacked.app.IconManager_Singleton;



[Bindable]
private var __iconManager:IconManager_Singleton; 
private var __appWideSingleton:AppWide_Singleton;
private var __appWideEventDispatcher:AppWideEventDispatcher_Singleton;

private var __camSpot_V:Video;
private var __camSpot_UIC:UIComponent;
private var __camSpot_NS:NetStream;
private var __camSpot_ST:SoundTransform;
private var __statsTimer:Timer;

[Bindable]
public var userInfoObj:Object;
public var userMetaData:Object;
public var statsInfoObj:Object;
public var hasStatsTimerListener:Boolean;

public var isPlayingVideo:Boolean;
public var isPlayingAudio:Boolean;
public var wasPlayingVideo:Boolean;
public var wasPlayingAudio:Boolean;




public function get camSpot_V():Video
{
	return __camSpot_V;
}


private function preinitializeHandler(event:FlexEvent):void
{
	__appWideEventDispatcher = AppWideEventDispatcher_Singleton.getInstance();
	__appWideSingleton = AppWide_Singleton.getInstance();
	__iconManager = IconManager_Singleton.getInstance();
	
	event = null;
}


private function camSpotCreationCompleteHandler(event:FlexEvent):void
{
	trace("|###| CamSpot |###|>  LOADED");
	
	// add this camspot to the list of camSpotIDs
	if (__appWideSingleton.camSpotIDs_A.indexOf(this.id) == -1)
	{
		__appWideSingleton.camSpotIDs_A.push(this.id);
		//__appWideSingleton.camSpotIDs_A.sort();
	}
	
	if (this.id == 'camSpot6')
		resizeCamSpot(320, 240);
	else
		resizeCamSpot(160, 120);
	
	setupUserInfoObj();
	
	//if (!__appWideEventDispatcher.hasEventListener("setHost"))
	//{
	//	__appWideEventDispatcher.addEventListener("setHost", setHost, false,0,true);
	//}
	
	event.stopPropagation();
	
	event = null;
}


private function setupUserInfoObj():void
{
	// setup the default userInfoObj vars
	userInfoObj = new Object();
	userInfoObj.acctID = '0';
	userInfoObj.acctName = '';
	userInfoObj.userID = '0';
	userInfoObj.userName = '';
	userInfoObj.defaultQuality = __appWideSingleton.appInfoObj.defaultQuality;
	//userInfoObj.viewedByUserIDs_A = __appWideSingleton.userInfoObj.viewedByUserIDs_A;
	//userInfoObj.heardByUserIDs_A = __appWideSingleton.userInfoObj.heardByUserIDs_A;
	userInfoObj.volume = 0.7;
	userInfoObj.isPrivate = false;
	userInfoObj.isUsersVideoOn = false;
	userInfoObj.isUsersAudioOn = false;
	userInfoObj.isPlayingVideo = false;
	userInfoObj.isPlayingAudio = false;
	userInfoObj.wasPlayingVideo = false;
	userInfoObj.wasPlayingAudio = false;
	userInfoObj.isManuallyUnmuted = false;
	
	userMetaData = new Object();
}


private function setupNetStream():void
{
	if (!__camSpot_NS)
	{
		// do not create a new NetStream unless the NetConnection is already connected
		if (!parentApplication.loginPanel.nc.connected) return;
		
		// create/connect the NetStream if it hasnt been created yet
		__camSpot_NS = new NetStream(parentApplication.loginPanel.nc);
		
		// set the NetStreams client to this so this class will handle function calls over the NetStream
		__camSpot_NS.client = this;
		
		//__camSpot_ST = new SoundTransform();
		
		// listen for NetStatusEvents on the NetStream
		if (!__camSpot_NS.hasEventListener(NetStatusEvent.NET_STATUS)) { __camSpot_NS.addEventListener(NetStatusEvent.NET_STATUS, netStreamStatusEventHandler, false,0,true); }
		if (!__camSpot_NS.hasEventListener(IOErrorEvent.NETWORK_ERROR)) { __camSpot_NS.addEventListener(IOErrorEvent.NETWORK_ERROR, netStreamIOErrorHandler, false,0,true); }
		if (!__camSpot_NS.hasEventListener(AsyncErrorEvent.ASYNC_ERROR)) { __camSpot_NS.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netStreamAsyncErrorHandler, false,0,true); }
		if (!__camSpot_NS.hasEventListener(SecurityErrorEvent.SECURITY_ERROR)) { __camSpot_NS.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netStreamSecurityError, false,0,true); }
		
		// set the buffer time of the NetStream.
		// live stream is usually 0.00
		__camSpot_NS.bufferTime = 0.000; // was 0.05
		__camSpot_NS.bufferTimeMax = 0.000;
		__camSpot_NS.useJitterBuffer = true;
		__camSpot_NS.inBufferSeek = false; // TEST
		
		// dont buffer anything when pausing, since this is live
		__camSpot_NS.maxPauseBufferTime = 0.000;
		__camSpot_NS.backBufferTime = 0.000;
		
		// set rtmfp specific properties for the subscribers NetStream
		if (__appWideSingleton.appInfoObj.selectedConnectionProtocol == "rtmfp")
		{
			__camSpot_NS.dataReliable = false;
			__camSpot_NS.videoReliable = false;
			__camSpot_NS.audioReliable = false;
			//__camSpot_NS.multicastWindowDuration = 8;
			//__camSpot_NS.client.onPeerConnect = function(subscriber:NetStream):Boolean { subscriber = null; return true; };
		}
	} else {
		// reset and remove the NetStream
		__camSpot_NS.attachCamera(null);
		__camSpot_NS.attachAudio(null);
		//__camSpot_NS.play(false);
		__camSpot_NS.close();
		
		// remove event listeners, and reset the NetStream
		if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(NetStatusEvent.NET_STATUS))) { __camSpot_NS.removeEventListener(NetStatusEvent.NET_STATUS, netStreamStatusEventHandler); }
		if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(IOErrorEvent.NETWORK_ERROR))) { __camSpot_NS.removeEventListener(IOErrorEvent.NETWORK_ERROR, netStreamIOErrorHandler); }
		if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(AsyncErrorEvent.ASYNC_ERROR))) { __camSpot_NS.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, netStreamAsyncErrorHandler); }
		if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(SecurityErrorEvent.SECURITY_ERROR))) { __camSpot_NS.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, netStreamSecurityError); }
		
		__camSpot_NS.dispose();
		__camSpot_NS = null;
		__camSpot_ST = null;
		
		if (__camSpot_NS)
			debugMsg("setupNetStream->\t<WARNING>\tcamSpot_NS: "+__camSpot_NS);
		
		// now recreate a new NetStream
		setupNetStream();
	}
}


public function isPlaying():Boolean
{
	if (isPlayingVideo || isPlayingAudio)
	{
		return true;
	} else {
		return false;
	}
}


// called when a user clicks a CamSpot and its userInfoObj.userID != 0
private function camSpotClickHandler(event:MouseEvent):void
{
	if (userInfoObj.userID == 0)
	{
		// CamSpot is empty
		debugMsg("camSpotClickHandler->  event.target: "+event.target+"  event.currentTarget: "+event.currentTarget);
	}
	
	event.stopPropagation();
	
	event = null;
}


private function formatUserName():void
{
	//if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
	//statsBtn.includeInLayout = true;
	
	userName_L.text = StringUtil.trim(userInfoObj.userName);
	userName_L.toolTip = userName_L.text;
}


public function attachUser(userObj:Object):void
{
	debugMsg("attachUser->  userID: "+userObj.userID+
		"  userName: "+userObj.userName+
		"  isUsersVideoOn: "+userObj.isUsersVideoOn+
		"  isUsersAudioOn: "+userObj.isUsersAudioOn+
		"  isPlayingVideo: "+userObj.isPlayingVideo+
		"  isPlayingAudio: "+userObj.isPlayingAudio+
		"  isManuallyUnmuted: "+userObj.isManuallyUnmuted+
		"  wasPlayingVideo: "+userObj.wasPlayingVideo+
		"  wasPlayingAudio: "+userObj.wasPlayingAudio+
		"  defaultQuality: "+userObj.defaultQuality+
		"  isUseOthersQualityChecked: "+__appWideSingleton.appInfoObj.isUseOthersQualityChecked);
	
	// check if the userObj is not the same user
	if (userObj.userID != userInfoObj.userID)
	{
		// set the new user object
		//userInfoObj = userObj;
		userInfoObj.acctID = userObj.acctID;
		userInfoObj.acctName = userObj.acctName;
		userInfoObj.userID = userObj.userID;
		userInfoObj.userName = userObj.userName;
		userInfoObj.isPlayingVideo = userObj.isPlayingVideo;
		userInfoObj.isPlayingAudio = userObj.isPlayingAudio;
		userInfoObj.wasPlayingVideo = userObj.wasPlayingVideo;
		userInfoObj.wasPlayingAudio = userObj.wasPlayingAudio;
		
		if ((userObj.isUsersVideoOn!=null)&&(userObj.isUsersVideoOn!=undefined))
		{
			userInfoObj.isUsersVideoOn = userObj.isUsersVideoOn;
		}
		if ((userObj.isUsersAudioOn!=null)&&(userObj.isUsersAudioOn!=undefined))
		{
			userInfoObj.isUsersAudioOn = userObj.isUsersAudioOn;
		}
		if ((userObj.isManuallyUnmuted!=null)&&(userObj.isManuallyUnmuted!=undefined))
		{
			userInfoObj.isManuallyUnmuted = userObj.isManuallyUnmuted;
		}
		if ((userObj.volume!=null)&&(userObj.volume!=undefined))
		{
			userInfoObj.volume = userObj.volume;
		}
		
		// create the Video and UIComponent
		setupVideo();
		
		// if this is the local user, show the local camera
		if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
		{
			// attach the local camera to the video (move to MediaManager startVideo?)
			if (parentApplication.lobby.mediaManager.isMyVideoOn)
			{
				__camSpot_V.attachCamera(parentApplication.lobby.mediaManager.camera);
				
				userInfoObj.isPlayingVideo = true;
			}
			
			// TODO (move to MediaManager startAudio?)
			__appWideEventDispatcher.addEventListener('onLocalUserPublishAudio', onLocalUserPublishAudio, false,0,true);
			
			if (parentApplication.lobby.mediaManager.isMyAudioOn)
			{
				startVUMeter();
			}
		} else {
			// TEMP: ....
			// TODO: ask for permission if the other user is set to private.
			
			// override the defaultQuality with the local setting
			if (__appWideSingleton.appInfoObj.isUseOthersQualityChecked)
				userInfoObj.defaultQuality = userObj.defaultQuality;
			
			// setup the NetStream
			setupNetStream();
			
			// FIX
			// set any previously defined volume
			if (userInfoObj.volume)
			{
				camSpotVolume_VS.value = userInfoObj.volume;
			}
			
			// attach the NetStream
			__camSpot_V.attachNetStream(__camSpot_NS);
			
			// dont buffer anything when pausing, since this is live
			__camSpot_NS.bufferTime = 0.000;
			__camSpot_NS.bufferTimeMax = 0.000;
			__camSpot_NS.backBufferTime = 0.000;
			__camSpot_NS.maxPauseBufferTime = 0.000;
			__camSpot_NS.useJitterBuffer = true;
			__camSpot_NS.inBufferSeek = true; // TEST
			
			// play the NetStream
			__camSpot_NS.play("user_" + userInfoObj.userID, -1,-1, true);
			
			// check whether the users video is on/off
			if (userInfoObj.isUsersVideoOn)
			{
				if (__appWideSingleton.appInfoObj.isAllCamsOffChecked)
				{
					// dont play the video
					playMedia("video",false);
				} else {
					// play the video
					playMedia("video",true);
				}
			} else {
				videoOnOffBtn.source = null;
				videoOnOffBtn.source = __iconManager.getIcon('app_videoOff');
			}
			
			// play the audio of the room host if selected
			if ((__appWideSingleton.appInfoObj.isUnmuteRoomHostChecked == true) &&
				(parentApplication.lobby.userListPanel.getUserObj(userInfoObj.userID).isHost))
			{
				playMedia("audio",true);
			// else check whether the users audio is on/off (move?)
			} else if (userInfoObj.isUsersAudioOn) {
				// if allAudioOffOnJoin_CB is selected
				if (__appWideSingleton.appInfoObj.isAllAudioOffChecked)
				{
					// already playing the audio before switching cams
					if (userInfoObj.isPlayingAudio)
					{
						playMedia("audio",true);
					} else {
						// dont play the audio
						playMedia("audio",false);
					}
				} else {
					// play the audio
					playMedia("audio",true);
				}
			} else {
				playMedia("audio",false);
			}
		}
	}
	
	userObj = null;
}

/*
// TEST:
// moved to Lobby.as
private function setHost(userID:Number):void
{
	debugMsg("setHost->  userID: "+userID);
	
	if (userInfoObj.userID == 0)
	{
		// CamSpot is empty, exit
		return;
	}
	
	// TODO
	// if this is not the main cam,
	// and this is now the host,
	// then swap it with the main cam
	
	// TODO: fix auto un/mute room host
	// TODO: fix un/mute of new/old hosts 
	
	// if the room host on main option is on
	if (__appWideSingleton.appInfoObj.isRoomHostOnMainChecked)
	{
		// if this is cam is already playing the new host,
		// or the host was reset, and this cam is playing 
		// the main host, then swap to main
		//
		if ((userInfoObj.userID == userID)||
			((userID==0)&&
				(parentApplication.lobby.userListPanel.getUserObj(userInfoObj.userID).adminType=="rh")))
		{
			userInfoObj.isHost = true;
			parentApplication.lobby.switchToMain(userInfoObj);
		}
	}
}
*/

// TEST:
private function onLocalUserPublishAudio(event:CustomEvent):void
{
	if ((event.eventObj.isPublishingAudio) &&
		(parentApplication.lobby.mediaManager.localUserAudioInputVolumeMeter == null))
	{
		startVUMeter();
	}
	
	event = null;
}


public function startVUMeter():void
{
	//appVUMeter_BMI.clearOnLoad = true;
	appVUMeter_BMI.source = __iconManager.getIcon('app_vumeter');
	
	//appVUMeter_BMI.mask.scaleY = 0; // start at 0 to hide the maskee by default
	
	// TEST:
	// start mic volume meter 
	// TODO check if and stop listening for mic SampleDataEvent
	/*if (parentApplication.lobby.mediaManager.mic)
	{
	if (!parentApplication.lobby.mediaManager.mic.hasEventListener(SampleDataEvent.SAMPLE_DATA))
	{
	//parentApplication.lobby.mediaManager.mic.addEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData, false,0,true);
	}
	}*/
	
	
	
	// "detach" the VUmeter from the MediaManager singleton
	if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
	{
		parentApplication.lobby.mediaManager.localUserAudioInputVolumeMeter = appVUMeter_BMI;
	}
}


// stop/cleanup mic volume meter 
public function stopVUMeter():Boolean
{
	/*if (parentApplication.lobby.mediaManager.mic)
	{
	if (parentApplication.lobby.mediaManager.mic.hasEventListener(SampleDataEvent.SAMPLE_DATA))
	{
	//parentApplication.lobby.mediaManager.mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
	}
	}*/
	
	// stop the volumeMeterActivityTimer
	// (handled in MediaManager.stopAudio)
	
	// "detach" the VUmeter from the MediaManager singleton
	if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
	{
		parentApplication.lobby.mediaManager.localUserAudioInputVolumeMeter = null;
	}
	
	if (appVUMeter_BMI)
	{
		//appVUMeter_BMI.mask.scaleY = 1;
		appVUMeter_BMI.source = null;
	}
	
	return true; // to tell the caller (sometimes mediaManager) the listener is gone so it can gc the mic
}


public function onVolumeMeterUpdateHandler(event:TimerEvent):void
{
	var micActivityLevel:int = parentApplication.lobby.mediaManager.mic.activityLevel;
	var appVUMeterHeight:int = appVUMeter_BMI ? appVUMeter_BMI.height : 0;
	
	//debugMsg("onVolumeMeterUpdateHandler->  activity: "+parentApplication.lobby.mediaManager.mic.activityLevel+"%");
	
	if (appVUMeter_BMI)
	{
		appVUMeter_BMI.mask.y = Math.round(appVUMeterHeight-(appVUMeterHeight*(micActivityLevel/100)));
	}
	
	event = null;
}


public function gotMicData(micData:SampleDataEvent):void
{
	var micActivityLevel:int = parentApplication.lobby.mediaManager.mic.activityLevel;
	//debugMsg("gotMicData->  activity: "+parentApplication.lobby.mediaManager.mic.activityLevel+"%");
	
	//var currentMicActivityLevel:int = (microphone.activityLevel+50) / 100;
	//var currentMicActivityLevel:uint = (microphone.activityLevel / 100);
	
	// resize/rescale volume meter mask using microphone.activityLevel
	//appVUMeter_BM.scaleY = microphone.activityLevel / 100;
	//appVUMeter_BMI.mask.scaleY = (parentApplication.lobby.mediaManager.mic.activityLevel / 100);
	
	// move to the end of the vumeter image
	// (show the meter starting from the beginning)
	appVUMeter_BMI.mask.y = Math.round(appVUMeter_BMI.height-(appVUMeter_BMI.height*(micActivityLevel/100))); // buggy, always looks too low
	
	//debugMsg("gotMicData->  mic.activityLevel: "+micActivityLevel+"%  appVUMeter_BMI: "+appVUMeter_BMI.x+","+appVUMeter_BMI.y+","+appVUMeter_BMI.width+","+appVUMeter_BMI.height+"  appVUMeterMask: "+appVUMeter_BMI.mask.x+","+appVUMeter_BMI.mask.y+","+appVUMeter_BMI.mask.width+","+appVUMeter_BMI.mask.height);
	
	micData = null;
}


public function playMedia(media:String, onOff:Boolean):void
{
	debugMsg("playMedia->  media: "+media+"  onOff: "+onOff);
	
	if (!__camSpot_NS) return;
	
	switch (media)
	{
		case "video":
			__camSpot_NS.receiveVideo(onOff);
			
			isPlayingVideo = onOff;
			
			userInfoObj.isPlayingVideo = onOff;
			
			if (onOff)
			{
				if ((__camSpot_NS.videoStreamSettings)&&
					(__camSpot_NS.videoStreamSettings.codec))
				{
					if (__camSpot_NS.videoStreamSettings.codec == 'H264Avc') return;
					
					// set the FPS depending on the defaultQuality
					switch (userInfoObj.defaultQuality)
					{
						case "low" :
							__camSpot_NS.receiveVideoFPS(1);
							break;
						case "medium" :
							__camSpot_NS.receiveVideoFPS(3);
							break;
						case "high" :
							__camSpot_NS.receiveVideoFPS(6);
							break;
						case "hd" :
							__camSpot_NS.receiveVideoFPS(8);
							break;
						default :
							__camSpot_NS.receiveVideoFPS(8);
							break;
					}
				}
				
				videoOnOffBtn.source = null;
				videoOnOffBtn.source = __iconManager.getIcon('app_videoOn');
				
				// TEMP:
				// pass the local users clientID, and the targetUserID with startViewingUser 
				// to the user being viewed.
				__appWideSingleton.localNetConnection.call('mediaManager.startViewingUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
			} else {
				videoOnOffBtn.source = null;
				videoOnOffBtn.source = __iconManager.getIcon('app_videoOff');
				
				// TEMP:
				__appWideSingleton.localNetConnection.call('mediaManager.stopViewingUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
			}
			break;
		case "audio":
			__camSpot_NS.receiveAudio(onOff);
			
			isPlayingAudio = onOff;
			
			userInfoObj.isPlayingAudio = onOff;
			
			if (onOff)
			{
				audioOnOffBtn.source = null;
				audioOnOffBtn.source = __iconManager.getIcon('app_audioOn');
				
				// set the volume
				if (!userInfoObj.volume)
					userInfoObj.volume = 0.7;
				
				camSpotVolume_VS.value = userInfoObj.volume;
				
				__camSpot_ST = __camSpot_NS.soundTransform;
				
				__camSpot_ST.volume = userInfoObj.volume;
				
				__camSpot_NS.soundTransform = __camSpot_ST;
				
				// TEMP:
				__appWideSingleton.localNetConnection.call('mediaManager.startListeningToUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
			} else {
				audioOnOffBtn.source = null;
				audioOnOffBtn.source = __iconManager.getIcon('app_audioOff');
				
				// TEMP:
				__appWideSingleton.localNetConnection.call('mediaManager.stopListeningToUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
			}
			break;
	}
	
	// ignore stale objects in the userList_DP
	if (!onOff && !parentApplication.lobby.userListPanel.getUserObj(userInfoObj.userID))
	{
		parentApplication.lobby.undockCamSpot(userInfoObj);
	}
	
	media = null;
}


// create the Video object and add it to the camSpot_UIC
private function setupVideo():void
{
	// this UIC is not removed during .reset, like the Video is
	if (!__camSpot_UIC)
	{
		__camSpot_UIC = new UIComponent();
		__camSpot_UIC.left = 0;
		__camSpot_UIC.right = 0;
		__camSpot_UIC.top = 0;
		__camSpot_UIC.bottom = 0;
		__camSpot_UIC.mask = camSpot_BG_rect.mask;
		
		// add on top of the background rect
		this.addElementAt(__camSpot_UIC, getElementIndex(camSpot_BG_rect) + 1);
		
		__camSpot_UIC.addEventListener(MouseEvent.MOUSE_DOWN, camSpot_mouseDownHandler, false,0,true);
		__camSpot_UIC.addEventListener(MouseEvent.MOUSE_UP, camSpot_mouseUpHandler, false,0,true);
	}
	
	// possibly set this to the Cameras video h/w, later
	if (!__camSpot_V)
	{
		__camSpot_V = new Video(this.width, this.height);
		
		__camSpot_UIC.addChild(__camSpot_V);
		
		// enable smoothing for non-fullscreen video
		if (this.width <= 320)
			__camSpot_V.smoothing = true;
		
		// test filter
		//var _vidFilter_CF:ConvolutionFilter = new ConvolutionFilter(3, 3, [-1, -1, -1, -1, 12, -1, -1, -1, -1], 4, 0);
		//__camSpot_V.filters = [_vidFilter_CF];
	}
	
	/* camSpot_UIC: "+__camSpot_UIC+" */
	debugMsg("setupVideo->  camSpot_V: "+__camSpot_V+"  camSpot_V.width: "+__camSpot_V.width+"  camSpot_V.height: "+__camSpot_V.height+"  this.width: "+this.width+"  this.height: "+this.height);
	
	// set the buttons
	if (!xImgBtn.source) xImgBtn.source = __iconManager.getIcon('app_x');
	if (!arrowImgBtn.source) arrowImgBtn.source = __iconManager.getIcon('app_arrow');
	
	// is if this is not the local user..
	if (userInfoObj.userID != parentApplication.lobby.mediaManager.userID)
	{
		// show the default icons
		if (!statsCurrentFPS_Img.source) statsCurrentFPS_Img.source = __iconManager.getIcon('app_film');
		if (!statsDroppedFPS_Img.source) statsDroppedFPS_Img.source = __iconManager.getIcon('app_film_delete');
	} else {
		// show the webcam icons..
		// TODO: add video/audio pause toggling buttons
		if (!statsCurrentFPS_Img.source) statsCurrentFPS_Img.source = __iconManager.getIcon('app_webcam');
		if (!statsDroppedFPS_Img.source) statsDroppedFPS_Img.source = __iconManager.getIcon('app_webcam_delete');
	}
	
	if (!statsCurrentBPS_Img.source) statsCurrentBPS_Img.source = __iconManager.getIcon('app_lightning');
	if (!statsMaxBPS_Img.source) statsMaxBPS_Img.source = __iconManager.getIcon('app_lightning_delete');
	if (!toggleBWGraphBtn.source) toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line');
	if (!camSpotInfoBtn.source) camSpotInfoBtn.source = __iconManager.getIcon('app_info');
	
	toggleBWGraphBtn.enabled = false;
	
	statsHGroup.visible = true;
	//statsBtn.includeInLayout = true;
	
	statsCurrentFPS_L.text = "0";
	statsDroppedFPS_L.text = "0";
	statsCurrentBPS_L.text = "0";
	statsMaxBPS_L.text = "0";
	
	// show the userName
	formatUserName();
	
	this.alpha = 1;
}


public function resizeCamSpot(w:int, h:int):void
{
	this.width = w;
	this.height = h;
	
	if (__camSpot_UIC)
	{
		__camSpot_UIC.width = w;
		__camSpot_UIC.height = h;
	}
	
	if (__camSpot_V)
	{
		__camSpot_V.width = w;
		__camSpot_V.height = h;
	}
	
	if (this.id == "camSpot6")
	{
		arrowImgBtn.toolTip = "Move to an empty cam";
		
		// .styleManager.getStyleDeclaration('.userNameLabel') 
		userName_L.setStyle("fontSize", 18);
		
		camSpotVolume_VS.height = ((this.height - btnVGroup.height) * 0.75);
	} else {
		btnVGroup.width = 15;
		btnVGroup.height = 60;
		xImgBtn.width = 15;
		xImgBtn.height = 15;
		arrowImgBtn.width = 15;
		arrowImgBtn.height = 15;
		videoOnOffBtn.width = 15;
		videoOnOffBtn.height = 15;
		audioOnOffBtn.width = 15;
		audioOnOffBtn.height = 15;
		
		statsGroup.height = 10;
		statsCurrentFPS_Img.width = 8;
		statsCurrentFPS_Img.height = 8;
		statsCurrentFPS_L.setStyle('fontFamily', 'sans-serif');
		statsCurrentFPS_L.setStyle('fontSize', 8);
		statsDroppedFPS_Img.width = 8;
		statsDroppedFPS_Img.height = 8;
		statsDroppedFPS_L.setStyle('fontFamily', 'sans-serif');
		statsDroppedFPS_L.setStyle('fontSize', 8);
		statsCurrentBPS_Img.width = 8;
		statsCurrentBPS_Img.height = 8;
		statsCurrentBPS_L.setStyle('fontFamily', 'sans-serif');
		statsCurrentBPS_L.setStyle('fontSize', 8);
		statsMaxBPS_Img.width = 8;
		statsMaxBPS_Img.height = 8;
		statsMaxBPS_L.setStyle('fontFamily', 'sans-serif');
		statsMaxBPS_L.setStyle('fontSize', 8);
		
		toggleBWGraphBtn.width = 8;
		toggleBWGraphBtn.height = 8;
		camSpotInfoBtn.width = 8;
		camSpotInfoBtn.height = 8;
		
		arrowImgBtn.toolTip = "Swap this cam with the large cam";
		
		// .styleManager.getStyleDeclaration('.userNameLabel') 
		userName_L.setStyle("fontSize", 12);
		userName_L.height = 15;
		
		camSpotVolume_VS.height = (this.height - btnVGroup.height);
	}
	
	userName_L.width = ((this.width - btnVGroup.width) - btnVGroup.width);
	
	camSpotVolume_VS.width = btnVGroup.width;
}


public function clearCamSpot():void
{
	if (userInfoObj.userID != 0)
	{
		if (__appWideEventDispatcher.hasEventListener('onLocalUserPublishAudio'))
		{
			__appWideEventDispatcher.removeEventListener('onLocalUserPublishAudio', onLocalUserPublishAudio);
		}
		
		if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
		{
			stopVUMeter();
		}
		
		if (__statsTimer)
		{
			if (hasStatsTimerListener) 
				__statsTimer.removeEventListener(TimerEvent.TIMER, onStatsTimerTickHandler);
			
			hasStatsTimerListener = false;
			
			// reset related bw graph data
			var bwChart_DP:ArrayCollection = parentApplication.applicationBar.bwChart.bwChart_DP;
			
			toggleBWGraphBtn.source = null;
			toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line');
			toggleBWGraphBtn.enabled = false;
			
			if ((parentApplication.applicationBar.bwChart.currentState == "camSpot") && 
				(bwChart_DP[0].camSpotID == this.id))
			{
				//__statsTimer.reset();
				__statsTimer.stop();
				
				bwChart_DP.removeAll();
				bwChart_DP.addItem({camSpotID:"", currentBytesPerSecond:0, maxBytesPerSecond:0, byteCount:0, streamTime:0});
			}
			
			bwChart_DP = null;
			__statsTimer = null;
		}
		
		if (__camSpot_UIC.contains(__camSpot_V))
		{
			__camSpot_V.attachCamera(null);
			__camSpot_V.attachNetStream(null);
			
			__camSpot_UIC.removeChild(__camSpot_V);
			__camSpot_V.clear();
			
			__camSpot_V = null;
		}
		
		if (__camSpot_UIC)
		{
			__camSpot_UIC.removeEventListener(MouseEvent.MOUSE_DOWN, camSpot_mouseDownHandler);
			__camSpot_UIC.removeEventListener(MouseEvent.MOUSE_UP, camSpot_mouseUpHandler);
			
			this.removeElement(__camSpot_UIC);
			
			__camSpot_UIC.mask = null;
			__camSpot_UIC = null;
		}
		
		// reset and remove the NetStream
		if (__camSpot_NS)
		{
			if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
			{
				__camSpot_NS.attachCamera(null);
				__camSpot_NS.attachAudio(null);
			} else {
				__camSpot_NS.play(false);
			}
			
			//__camSpot_NS.close();
			__camSpot_NS.dispose();
			
			// remove event listeners, and reset the NetStream
			if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(NetStatusEvent.NET_STATUS))) { __camSpot_NS.removeEventListener(NetStatusEvent.NET_STATUS, netStreamStatusEventHandler); }
			if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(IOErrorEvent.NETWORK_ERROR))) { __camSpot_NS.removeEventListener(IOErrorEvent.NETWORK_ERROR, netStreamIOErrorHandler); }
			if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(AsyncErrorEvent.ASYNC_ERROR))) { __camSpot_NS.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, netStreamAsyncErrorHandler); }
			if ((__camSpot_NS) && (__camSpot_NS.hasEventListener(SecurityErrorEvent.SECURITY_ERROR))) { __camSpot_NS.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, netStreamSecurityError); }
			
			__camSpot_NS.soundTransform = null;
			__camSpot_NS = null;
			__camSpot_ST = null;
		}
		
		isPlayingVideo = false;
		isPlayingAudio = false;
		wasPlayingVideo = false;
		wasPlayingAudio = false;
		
		statsBtn.includeInLayout = false;
		statsHGroup.visible = false;
		
		xImgBtn.source = null;
		arrowImgBtn.source = null;
		videoOnOffBtn.source = null;
		audioOnOffBtn.source = null;
		statsCurrentFPS_Img.source = null;
		statsDroppedFPS_Img.source = null;
		statsCurrentBPS_Img.source = null;
		statsMaxBPS_Img.source = null;
		toggleBWGraphBtn.source = null;
		camSpotInfoBtn.toolTip = null;
		camSpotInfoBtn.source = null;
		
		statsCurrentFPS_L.text = null;
		statsDroppedFPS_L.text = null;
		statsCurrentBPS_L.text = null;
		statsMaxBPS_L.text = null;
		
		userName_L.text = null;
		
		if (userName_L.toolTip != null)
		{
			userName_L.toolTip = "";
			userName_L.toolTip = null;
		}
		
		statsCurrentFPS_L.text = "0";
		statsDroppedFPS_L.text = "0";
		statsCurrentBPS_L.text = "0";
		statsMaxBPS_L.text = "0";
		
		userInfoObj = null;
		userMetaData = null;
		
		this.alpha = 0.4;
		
		setupUserInfoObj();
		
		debugMsg("clearCamSpot->  CLEARED  "+this.id+"  camSpot_UIC: "+__camSpot_UIC+"  camSpot_V: "+__camSpot_V+"  camSpot_NS: "+__camSpot_NS+"  userInfoObj.userID: "+userInfoObj.userID+"  userMetaData: "+userMetaData);
	}
}


private function xImgBtn_clickHandler(event:MouseEvent):void
{
	// TEST
	for (var i:int = 0; i < parentApplication.lobby.userListPanel.userList_DP.length; ++i) 
	{
		if (parentApplication.lobby.userListPanel.userList_DP[i].userID == userInfoObj.userID)
		{
			parentApplication.lobby.userListPanel.userList_DP[i].doNotDock = true;
			break;
		}
	}
	
	parentApplication.lobby.undockCamSpot(userInfoObj);
	
	event.stopPropagation();
	
	event = null;
}


private function arrowImgBtn_clickHandler(event:MouseEvent):void
{
	if (this.id == 'camSpot6')
		parentApplication.lobby.switchCamSpot(userInfoObj);
	else
		parentApplication.lobby.switchToMain(userInfoObj);
	
	event.stopPropagation();
	
	event = null;
}


private function videoOnOffBtn_clickHandler(event:MouseEvent):void
{
	//trace("|###| CamSpot.videoOnOffBtn_clickHandler |###|>  userName: "+userInfoObj.userName);
	
	// pause
	if (isPlayingVideo)
	{
		__camSpot_NS.receiveVideo(false);
		
		isPlayingVideo = false;
		
		userInfoObj.isPlayingVideo = false;
		
		videoOnOffBtn.source = null;
		videoOnOffBtn.source = __iconManager.getIcon('app_videoOff');
		
		// TEMP:
		__appWideSingleton.localNetConnection.call('mediaManager.stopViewingUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
	} else {
		// play
		__camSpot_NS.receiveVideo(true);
		
		isPlayingVideo = true;
		
		userInfoObj.isPlayingVideo = true;
		
		videoOnOffBtn.source = null;
		videoOnOffBtn.source = __iconManager.getIcon('app_videoOn');
		
		// TEMP:
		__appWideSingleton.localNetConnection.call('mediaManager.startViewingUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
	}
	
	event.stopPropagation();
	
	event = null;
}


private function audioOnOffBtn_clickHandler(event:MouseEvent):void
{
	//trace("|###| CamSpot.audioOnOffBtn_clickHandler |###|>  userName: "+userInfoObj.userName);
	
	// pause
	if (isPlayingAudio)
	{
		__camSpot_NS.receiveAudio(false);
		
		isPlayingAudio = false;
		
		userInfoObj.isPlayingAudio = false;
		if (userInfoObj.isManuallyUnmuted) 
			userInfoObj.isManuallyUnmuted = false;
		
		audioOnOffBtn.source = null;
		audioOnOffBtn.source = __iconManager.getIcon('app_audioOff');
		
		// TEMP:
		__appWideSingleton.localNetConnection.call('mediaManager.stopListeningToUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
	} else {
		// play
		__camSpot_NS.receiveAudio(true);
		
		isPlayingAudio = true;
		
		userInfoObj.isPlayingAudio = true;
		userInfoObj.isManuallyUnmuted = true;
		
		audioOnOffBtn.source = null;
		audioOnOffBtn.source = __iconManager.getIcon('app_audioOn');
		
		// TEMP:
		__appWideSingleton.localNetConnection.call('mediaManager.startListeningToUser', null, parentApplication.lobby.mediaManager.clientID, userInfoObj.userID);
	}
	
	event.stopPropagation();
	
	event = null;
}





private function camSpotInfoBtn_clickHandler(event:MouseEvent):void
{
	var bwChart_DP:ArrayCollection = parentApplication.applicationBar.bwChart.bwChart_DP;
	
	// if the timer doesnt exist, define and start it
	if (!__statsTimer)
	{
		__statsTimer = __appWideSingleton.statsTimer;
		
		if (!hasStatsTimerListener)
		{
			__statsTimer.addEventListener(TimerEvent.TIMER, onStatsTimerTickHandler, false,0,true);
			
			hasStatsTimerListener = true;
		}
		
		toggleBWGraphBtn.source = null;
		toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line_add');
		toggleBWGraphBtn.enabled = true;
		
		if (!__statsTimer.running)
			__statsTimer.start();
	} else {
		// if the timer exists already,
		// stop all stats for this camspot
		if (hasStatsTimerListener)
		{
			__statsTimer.removeEventListener(TimerEvent.TIMER, onStatsTimerTickHandler);
			
			__statsTimer = null;
			
			hasStatsTimerListener = false;
		}
		
		// stop the bw graph
		if ((bwChart_DP.length) &&
			(bwChart_DP[0].camSpotID == this.id))
		{
			//__statsTimer.reset();
			
			bwChart_DP.removeAll();
			bwChart_DP.addItem({camSpotID:"", currentBytesPerSecond:0, maxBytesPerSecond:0, byteCount:0, streamTime:0});
			
			toggleBWGraphBtn.source = null;
			toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line');
			toggleBWGraphBtn.enabled = false;
		}
		
		statsCurrentFPS_L.text = "0";
		statsDroppedFPS_L.text = "0";
		statsCurrentBPS_L.text = "0";
		statsMaxBPS_L.text = "0";
	}
	
	event.stopPropagation();
	
	bwChart_DP = null;
	event = null;
}


private function toggleBWGraphBtn_clickHandler(event:MouseEvent):void
{
	if (parentApplication.applicationBar.bwChart.currentState != "camSpot") return;
	
	var bwChart_DP:ArrayCollection = parentApplication.applicationBar.bwChart.bwChart_DP;
	
	// if this camSpotID is already measuring bandwidth
	if (bwChart_DP[0].camSpotID == this.id)
	{
		//__statsTimer.reset();
		
		// reset the bw graph
		bwChart_DP.removeAll();
		bwChart_DP.addItem({camSpotID:"", currentBytesPerSecond:0, maxBytesPerSecond:0, byteCount:0, streamTime:0});
		
		// show the "start graph" button
		toggleBWGraphBtn.source = null;
		toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line_add');
	} else if (bwChart_DP[0].camSpotID == "") {
		// if the bw graph is empty,
		// reset the bw graph
		//__statsTimer.reset();
		
		var _streamTime:Number = ((userInfoObj.userID == parentApplication.lobby.mediaManager.userID) && (parentApplication.lobby.mediaManager.localNetStream)) ? parentApplication.lobby.mediaManager.localNetStream.time : __camSpot_NS.time;
		bwChart_DP.removeAll();
		bwChart_DP.addItem({camSpotID:this.id, currentBytesPerSecond:0, maxBytesPerSecond:0, byteCount:0, streamTime:_streamTime});
		
		// show the "stop graph" button
		toggleBWGraphBtn.source = null;
		toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line_delete');
	}
	
	event.stopPropagation();
	
	bwChart_DP = null;
	event = null;
}


private function onStatsTimerTickHandler(event:TimerEvent):void
{
	//var bwChart_DP:ArrayCollection = parentApplication.applicationBar.bwChart.bwChart_DP;
	var statsInfoNS:NetStream;
	
	if (!statsInfoObj)
		statsInfoObj = new Object();
	
	// if the attached user is the local client
	if (userInfoObj.userID == parentApplication.lobby.mediaManager.userID)
	{
		// use the local clients NetStream
		statsInfoNS = parentApplication.lobby.mediaManager.localNetStream;
	} else {
		// else use the CamSpots NS
		statsInfoNS = __camSpot_NS;
	}
	
	if (!statsInfoNS)
	{
		statsCurrentFPS_L.text = "0";
		statsDroppedFPS_L.text = "0";
		statsCurrentBPS_L.text = "0";
		statsMaxBPS_L.text = "0";
		
		toggleBWGraphBtn.source = null;
		toggleBWGraphBtn.source = __iconManager.getIcon('app_chart_line');
		toggleBWGraphBtn.enabled = false;
		
		return;
	}
	
	statsInfoObj.camSpotID = this.id;
	
	// if this is the local user NetStream.*Codec
	// is the same (2048/128) and cannot be used.
	//
	// use the NetStream.info.metaData if it exists,
	// else use videoStreamSettings if it exists.
	if (statsInfoNS.info.metaData && statsInfoNS.info.metaData.videoCodec)
	{
		statsInfoObj.videoCodec = '  ['+statsInfoNS.info.metaData.videoCodec+']';
	} else {
		if (statsInfoNS.videoStreamSettings && statsInfoNS.videoStreamSettings.codec)
		{
			statsInfoObj.videoCodec = '  ['+statsInfoNS.videoStreamSettings.codec+']';
		} else if (statsInfoNS.videoCodec) {
			// TODO: check if this is the local user and get the codec locally,
			// else derive from the uint
			//statsInfoObj.videoCodec = '  ['+statsInfoNS.videoCodec+']';
			statsInfoObj.videoCodec = (statsInfoNS.videoCodec==7 ? '  H.264'+'  ['+statsInfoNS.videoCodec+']' : '  Sorenson Spark'+'  ['+statsInfoNS.videoCodec+']');
		}
	}
	if (statsInfoNS.info.metaData && statsInfoNS.info.metaData.audioCodec)
	{
		statsInfoObj.audioCodec = '  ['+statsInfoNS.info.metaData.audioCodec+']';
	} else {
		if (statsInfoNS.audioCodec)
		{
			if (statsInfoNS.audioCodec==6)
			{
				statsInfoObj.audioCodec = '  Nellymoser'+'  ['+statsInfoNS.audioCodec+']';
			}
			if (statsInfoNS.audioCodec==11)
			{
				statsInfoObj.audioCodec = '  Speex'+'  ['+statsInfoNS.audioCodec+']';
			}
			// TODO: check if this is the local user and get the codec locally
			if (statsInfoNS.audioCodec==128)
			{
				statsInfoObj.audioCodec = '  ['+statsInfoNS.audioCodec+']';
			}
		}
	}
	
	//statsInfoObj.videoCodec = ((statsInfoNS.videoCodec==2048||statsInfoNS.videoCodec==7) ? '  H.264'+'  ['+statsInfoNS.videoCodec+']' : 'Sorenson Spark'+'  ['+statsInfoNS.videoCodec+']');
	//if (statsInfoNS.videoCodec) statsInfoObj.videoCodec = ((statsInfoNS.videoStreamSettings && statsInfoNS.videoStreamSettings.codec) ? '  ['+statsInfoNS.videoStreamSettings.codec+']' : '  ['+statsInfoNS.videoCodec+']');
	//if (statsInfoNS.audioCodec) statsInfoObj.audioCodec = ((statsInfoNS.audioCodec==6) ? '  Nellymoser'+'  ['+statsInfoNS.audioCodec+']' : '  ['+statsInfoNS.audioCodec+']');
	
	statsInfoObj.isLive = statsInfoNS.info.isLive;
	statsInfoObj.liveDelay = statsInfoNS.liveDelay;
	statsInfoObj.streamTime = Math.round(statsInfoNS.time);
	statsInfoObj.currentFPS = Math.round(statsInfoNS.currentFPS);
	statsInfoObj.droppedFrames = statsInfoNS.info.droppedFrames;
	statsInfoObj.byteCount = statsInfoNS.info.byteCount;
	statsInfoObj.bufferLength = statsInfoNS.bufferLength;
	statsInfoObj.bufferTime = statsInfoNS.bufferTime;
	statsInfoObj.bufferTimeMax = statsInfoNS.bufferTimeMax;
	statsInfoObj.backBufferTime = statsInfoNS.backBufferTime;
	statsInfoObj.maxPauseBufferTime = statsInfoNS.maxPauseBufferTime;
	statsInfoObj.currentBytesPerSecond = Math.round(statsInfoNS.info.currentBytesPerSecond);
	statsInfoObj.playbackBytesPerSecond = Math.round(statsInfoNS.info.playbackBytesPerSecond);
	statsInfoObj.maxBytesPerSecond = Math.round(statsInfoNS.info.maxBytesPerSecond);
	statsInfoObj.dataBufferByteLength = statsInfoNS.info.dataBufferByteLength;
	statsInfoObj.dataBufferLength = statsInfoNS.info.dataBufferLength;
	statsInfoObj.dataByteCount = statsInfoNS.info.dataByteCount;
	statsInfoObj.dataBytesPerSecond = Math.round(statsInfoNS.info.dataBytesPerSecond);
	statsInfoObj.videoBufferByteLength = statsInfoNS.info.videoBufferByteLength;
	statsInfoObj.videoBufferLength = statsInfoNS.info.videoBufferLength;
	statsInfoObj.videoByteCount = statsInfoNS.info.videoByteCount;
	statsInfoObj.videoBytesPerSecond = Math.round(statsInfoNS.info.videoBytesPerSecond);
	statsInfoObj.audioBufferByteLength = statsInfoNS.info.audioBufferByteLength;
	statsInfoObj.audioBufferLength = statsInfoNS.info.audioBufferLength;
	statsInfoObj.audioByteCount = statsInfoNS.info.audioByteCount;
	statsInfoObj.audioBytesPerSecond = Math.round(statsInfoNS.info.audioBytesPerSecond);
	statsInfoObj.SRTT = statsInfoNS.info.SRTT;
	statsInfoObj.nsBandwidthDelayProduct = Math.floor(statsInfoNS.info.currentBytesPerSecond * statsInfoNS.liveDelay);
	
	if (statsInfoNS.info.metaData && statsInfoNS.info.metaData.currentConnectionProtocol)
		statsInfoObj.currentConnectionProtocol = statsInfoNS.info.metaData.currentConnectionProtocol;
	if (statsInfoObj.currentConnectionProtocol=="rtmfp")
	{
		statsInfoObj.videoLossRate = statsInfoNS.info.videoLossRate;
		statsInfoObj.audioLossRate = statsInfoNS.info.audioLossRate;
		statsInfoObj.multicastAvailabilitySendToAll = statsInfoNS.multicastAvailabilitySendToAll;
		statsInfoObj.multicastAvailabilityUpdatePeriod = statsInfoNS.multicastAvailabilityUpdatePeriod;
		statsInfoObj.multicastFetchPeriod = statsInfoNS.multicastFetchPeriod;
		statsInfoObj.multicastPushNeighborLimit = statsInfoNS.multicastPushNeighborLimit;
		statsInfoObj.multicastRelayMarginDuration = statsInfoNS.multicastRelayMarginDuration;
		statsInfoObj.multicastWindowDuration = statsInfoNS.multicastWindowDuration;
		
		statsInfoObj.multicastInfo = statsInfoNS.multicastInfo;
		
		/*if (statsInfoNS.multicastInfo)
		{
			statsInfoNS.multicastInfo = null;
			delete statsInfoNS.multicastInfo;
		}*/
	}
	
	statsCurrentFPS_L.text = statsInfoObj.currentFPS.toString();
	statsDroppedFPS_L.text = statsInfoObj.droppedFrames.toString();
	statsCurrentBPS_L.text = statsInfoObj.currentBytesPerSecond.toString();
	statsMaxBPS_L.text = statsInfoObj.maxBytesPerSecond.toString();
	
	if ((parentApplication.applicationBar.bwChart.currentState == "camSpot") && 
		(parentApplication.applicationBar.bwChart.bwChart_DP[0].camSpotID == this.id))
	{
		parentApplication.applicationBar.bwChart.bwChart_DP.addItem(statsInfoObj);
	}
	
	/*
	for (var i:* in statsInfoObj)
	{
	}
	
	i = null;
	*/
	
	
	//camSpotInfoBtn.toolTip = null;
	//camSpotInfoBtn.toolTip = statsInfoObj.toString();
	
	// TODO: fix mem leak from this
	//camSpotInfoBtn.toolTip = ObjectUtil.toString(statsInfoObj) + (!statsInfoObj.multicastInfo ? '' : '\n\n' + ObjectUtil.toString(statsInfoObj.multicastInfo));
	
	/*
	 * TEST fix mem leak..
	 * still leaks, setting .toolTip on the
	 * UIComponent, http://i.imgur.com/tVJ1bwu.gif
	*/
	var tt:String = '';
	
	for (var i:* in statsInfoObj)
		tt += i+" = "+statsInfoObj[i]+"\n";
	/*
	if (statsInfoObj.multicastInfo)
	{
		for (i in statsInfoObj.multicastInfo)
			tt += i+" = "+statsInfoObj.multicastInfo[i]+"\n";
	}
	*/
	camSpotInfoBtn.toolTip = null;
	camSpotInfoBtn.toolTip = tt;
	
	i = null;
	tt = null;
	
	//debugMsg("onStatsTimerTickHandler->\tbwChart_DP.length: "+bwChart_DP.length+"\tstreamTime: "+statsInfoObj.streamTime+"\tmaxBytesPerSecond: "+statsInfoObj.maxBytesPerSecond+"\tcurrentBytesPerSecond: "+statsInfoObj.currentBytesPerSecond+"\tbufferTime: "+statsInfoObj.bufferTime+"\tbufferLength: "+statsInfoObj.bufferLength);
	
	event.stopPropagation();
	
	statsInfoObj = null;
	statsInfoNS = null;
	//bwChart_DP = null;
	event = null;
}


// TODO:
// show either cam or netstream stats
// depending on if this is the local client
private function statsBtn_clickHandler(event:MouseEvent):void
{
	/**/
	if ((parentApplication.lobby.mediaManager.camera) && 
		(parentApplication.lobby.mediaManager.isMyVideoOn))
	{
		trace("cam.name: "+parentApplication.lobby.mediaManager.camera.name);
		trace("cam.quality: "+parentApplication.lobby.mediaManager.camera.quality);
		trace("cam.bandwidth: "+parentApplication.lobby.mediaManager.camera.bandwidth);
		trace("cam.(max)fps: "+parentApplication.lobby.mediaManager.camera.fps);
		trace("cam.currentFPS: "+parentApplication.lobby.mediaManager.camera.currentFPS);
		trace("cam.motionLevel: "+parentApplication.lobby.mediaManager.camera.motionLevel);
		trace("cam.activityLevel: "+parentApplication.lobby.mediaManager.camera.activityLevel);
		trace("cam.keyFrameInterval: "+parentApplication.lobby.mediaManager.camera.keyFrameInterval);
		trace("cam.loopback: "+parentApplication.lobby.mediaManager.camera.loopback);
		trace("cam.width: "+parentApplication.lobby.mediaManager.camera.width);
		trace("cam.height: "+parentApplication.lobby.mediaManager.camera.height);
		//trace("cam.: "+parentApplication.lobby.mediaManager.camera.);
	}
	
	event.stopPropagation();
	
	event = null;
}









/**************** CamSpot Drag & Drop ******************/

private function dragEnterHandler(event:DragEvent):void
{
	if (event.dragSource.hasFormat("userInfoObj") && (event.currentTarget != event.dragInitiator))
	{
		// Accept the drop.
		DragManager.acceptDragDrop(event.currentTarget as IUIComponent);
		
		// set the toCamSpot
		var tmpObj:Object = event.dragSource.dataForFormat("userInfoObj");
		tmpObj.toCamSpot = this.id;
		
		// Add the updated data to the dragSource.
		event.dragSource.addData(tmpObj, "userInfoObj");
		
		debugMsg("dragEnterHandler->  fromCamSpot: "+tmpObj.fromCamSpot+"  toCamSpot: "+tmpObj.toCamSpot+"  event.type: "+event.type+"  event.target: "+event.target+"  event.currentTarget: "+event.currentTarget+"  event.dragInitiator: "+event.dragInitiator+"  event.relatedObject: "+event.relatedObject);
		
		tmpObj = null;
	}
	
	event.stopPropagation();
	
	event = null;
}


private function dragExitHandler(event:DragEvent):void
{
	debugMsg("dragExitHandler->  event.type: "+event.type+"  event.target: "+event.target+"  event.currentTarget: "+event.currentTarget+"  event.relatedObject: "+event.relatedObject);
	
	// reset the toCamSpot
	//var tmpObj:Object = event.dragSource.dataForFormat("userInfoObj");
	//tmpObj.toCamSpot = tmpObj.fromCamSpot;
	
	// Add the updated data to the dragSource.
	//event.dragSource.addData(tmpObj, "userInfoObj");
	
	event.stopPropagation();
	
	//tmpObj = null;
	event = null;
}


private function dragDropHandler(event:DragEvent):void
{
	if (event.currentTarget != event.dragInitiator)
	{
		debugMsg("dragDropHandler->\tevent.type: "+event.type+"\tevent.target: "+event.target+"\tevent.currentTarget: "+event.currentTarget+"\tevent.relatedObject: "+event.relatedObject);
	}
	
	event.stopPropagation();
	
	event = null;
}


private function dragCompleteHandler(event:DragEvent):void
{
	var dragItem:Object = event.dragSource.dataForFormat("userInfoObj");
	
	if (dragItem.toCamSpot != this.id)
	{
		debugMsg("dragCompleteHandler->  toCamSpot.userID: "+parentApplication.lobby[dragItem.toCamSpot].userInfoObj.userID+"  fromCamSpot: "+dragItem.fromCamSpot+"  toCamSpot: "+dragItem.toCamSpot+"  event.type: "+event.type+"  event.target: "+event.target+"  event.currentTarget: "+event.currentTarget+"  event.relatedObject: "+event.relatedObject);
		
		parentApplication.lobby.switchCamSpot(dragItem);
	}
	
	event.stopPropagation();
	
	event = null;
}


private function camSpot_mouseDownHandler(event:MouseEvent):void
{
	if (userInfoObj.userID != 0)
	{
		//debugMsg("camSpot_mouseDownHandler->  event.type: "+event.type+"  event.target: "+event.target+"  event.currentTarget: "+event.currentTarget+"  event.relatedObject: "+event.relatedObject);
		
		// create a DragSource object
		var dragSource:DragSource = new DragSource();
		
		// set the userInfoObj as the dragItem
		var dragItem:Object = userInfoObj;
		
		// set the FROM camspot (this camspot)
		dragItem.fromCamSpot = this.id;
		
		// set the TO camspot (changed by other camspots' drag enter handler)
		dragItem.toCamSpot = this.id;
		
		// Add the data to the object.
		dragSource.addData(dragItem, "userInfoObj");
		
		// Call the DragManager doDrag() method to start the drag. 
		DragManager.doDrag(this, dragSource, event);
		
		dragSource = null;
		dragItem = null;
	} else {
		camSpotClickHandler(event);
	}
	
	event.stopPropagation();
	
	event = null;
}


private function camSpot_mouseUpHandler(event:MouseEvent):void
{
	if (userInfoObj.userID != 0)
	{
		debugMsg("camSpot_mouseUpHandler->  event.target: "+event.target+"  event.currentTarget: "+event.currentTarget+"  event.relatedObject: "+event.relatedObject);
	}
	
	event.stopPropagation();
	
	event = null;
}


private function camSpot_mouseOverHandler(event:MouseEvent):void
{
	// DEBUG
	/*if (__camSpot_NS)
	camSpotInfoBtn.toolTip = __camSpot_NS.info.toString();
	else
	camSpotInfoBtn.toolTip = null;
	*/
	if (__camSpot_UIC)
	{
		this.alpha = 1;
		__camSpot_UIC.alpha = 0.7;
	} else {
		this.alpha = 0.2;
	}
	
	//this.setStyle("backgroundColor","#19B819");
	
	// show controls
	xImgBtn.alpha = 1;
	arrowImgBtn.alpha = 1;
	videoOnOffBtn.alpha = 1;
	audioOnOffBtn.alpha = 1;
	statsGroup.alpha = 1;
	
	event.stopPropagation();
	
	event = null;
}


private function camSpot_mouseOutHandler(event:MouseEvent):void
{
	//trace("|###| CamSpot.camSpot_mouseOutHandler |###|>  target: "+event.target+"  currentTarget: "+event.currentTarget+"  relatedObject: "+event.relatedObject);
	// DEBUG
	//this.toolTip = null;
	
	if (__camSpot_UIC)
	{
		__camSpot_UIC.alpha = 1;
		this.alpha = 1;
	} else {
		this.alpha = 0.4;
	}
	
	//this.setStyle("backgroundColor","#393939");
	
	// mouseOut into another button, the volume slider, or this camSpot..
	if (event.relatedObject == null || 
		event.relatedObject.parent == xImgBtn || 
		event.relatedObject.parent == arrowImgBtn || 
		event.relatedObject.parent == videoOnOffBtn || 
		event.relatedObject.parent == audioOnOffBtn || 
		event.relatedObject == camSpotVolume_VS.track ||
		event.relatedObject == camSpotVolume_VS.thumb)
	{
		// do nothing
	} else {
		xImgBtn.alpha = 0.2;
		arrowImgBtn.alpha = 0.2;
		videoOnOffBtn.alpha = 0.2;
		audioOnOffBtn.alpha = 0.2;
		statsGroup.alpha = 0.4;
		camSpotVolume_VS.visible = false;
	}
	
	event.stopPropagation();
	
	event = null;
}


private function audioOnOffBtn_mouseOverHandler(event:MouseEvent):void
{
	//trace("|###| CamSpot.audioOnOffBtn_mouseOverHandler |###|>  target: "+event.target+"  currentTarget: "+event.currentTarget);
	if (!camSpotVolume_VS.visible)
	{
		camSpotVolume_VS.visible = true;
	}
	
	event.stopPropagation();
	
	event = null;
}


private function audioOnOffBtn_mouseOutHandler(event:MouseEvent):void
{
	//trace("|###| CamSpot.audioOnOffBtn_mouseOutHandler |###|>  target: "+event.target+"  currentTarget: "+event.currentTarget+"  relatedObject: "+event.relatedObject);
	if (event.relatedObject == camSpotVolume_VS.track ||
		event.relatedObject == camSpotVolume_VS.thumb /*|| event.relatedObject == null*/)
	{
		// mouseOut into another button, the volume slider, or this camSpot_BC, do nothing..
	} else {
		camSpotVolume_VS.visible = false;
	}
	
	event.stopPropagation();
	
	event = null;
}


private function camSpotVolume_VS_mouseOutHandler(event:MouseEvent):void
{
	//trace("|###| CamSpot.camSpotVolume_VS_mouseOutHandler |###|>  target: "+event.target+"  currentTarget: "+event.currentTarget+"  relatedObject: "+event.relatedObject);
	if (event.relatedObject == camSpotVolume_VS.thumb || 
		event.relatedObject == camSpotVolume_VS.track)
	{
		// if the mouse is leaving the slider and into any of the buttons or the slider track/thumb, do nothing..
	} else {
		camSpotVolume_VS.visible = false;
	}
	
	event.stopPropagation();
	
	event = null;
}


private function camSpotVolume_VS_changeHandler(event:Event):void
{
	//trace("|###| CamSpot.camSpotVolume_VS_changeHandler |###|>  VOLUME CHANGED TO: "+event.target.value);
	
	// set the NetStreams soundTransform property to the camSpot_ST
	__camSpot_ST = __camSpot_NS.soundTransform;
	__camSpot_ST.volume = event.target.value;
	__camSpot_NS.soundTransform = __camSpot_ST;
	
	userInfoObj.volume = event.target.value;
	
	event.stopPropagation();
	
	event = null;
}






/*
NetStreamInfo QoS statistics:

Flash Player 10 introduces some QoS properties that provide useful information about the stream/video performance and client network capabilities. A new class, NetStreamInfo, encapsulates the new properties and can be retrieved by accessing the info property of a NetStream object.

The info property, when accessed, takes a snapshot of the current state of the stream and the internal buffers, and can be used to check the performance of various attributes and switch to a different stream if necessary. The following properties track the total data rate:

currentBytesPerSecond: NetStream buffer fill rate. This specifies the rate at which the NetStream buffer is being filled or is publishing in bytes per sec. It is calculated as a moving average of the data received by the stream or publishing over a period of a second. It is valid for both progressive and streaming cases of NetStream.
maxBytesPerSecond: NetStream buffer capacity. Valid only for receiving streams, it specifies the max capacity of the stream. This is the maximum rate at which the stream buffer can get data currently. The FMS server sends as much data as is needed by the player to play the stream, which is measured by the currentBytesPerSecond property above. However, the server could send more data if needed up to a maximum value, which is limited by the client's network connection. This property provides this maximum limit at a given point in time. This value would change dynamically along with any changes in the network speeds or capacity of the player's network environment. This property can be effectively used to calculate the best bit rate that a client could play for its network. While all the other properties could be used with any version of the FMS server, maxBytesPerSecond requires FMS 3.5 or later; otherwise, it will provide false low dips when the FMS server throttles the stream.
byteCount: NetStream buffer fill size. This specifies the total bytes which have arrived into the queue from the start of the session, regardless of how many have played or flushed. Also, it can be used to access the amount of data published by the stream. This value is useful in calculating the data rate on a different granularity of time than calculated by currentBytesPerSecond above. The application could set up a timer and calculate the difference in current value with a previous value and get the data rate during the time interval.
More specific information can be accessed for each type of data (video, audio, and data) independently through the following API properties (see also the complete list of NetStreamInfo properties in the ActionScript 3.0 Language and Components Reference):

audioByteCount: NetStream audio buffer fill size. This specifies the total audio bytes which have arrived into the queue from the start of the session. Also, it can be used to access the amount of audio data published by the stream.
audioBytesPerSecond: NetStream audio buffer fill size. This specifies the total audio bytes which have arrived into the queue from the start of the session. Also, it can be used to access the amount of audio data published by the stream.
videoByteCount: NetStream video buffer fill size. This specifies the total video bytes which have arrived into the queue from the start of the session. Also, it can be used to access the amount of video data published by the stream.
videoBytesPerSecond: NetStream video buffer fill rate. This specifies the rate at which the NetStream video buffer is being filled or is publishing in bytes per sec. It is calculated as a moving average of the video data received by the stream or publishing over a period of a second.
dataByteCount: NetStream data buffer fill size. This specifies the total data bytes which have arrived into the queue from the start of the session. Also, it can be used to access the amount of data messages published by the stream.
dataBytesPerSecond: NetStream data messages buffer fill rate. This specifies the rate at which the NetStream data message buffer is being filled or is publishing in bytes per sec. It is calculated as a moving average of the data messages received by the stream or publishing over a period of a second.
droppedFrames: Dropped frame count—the absolute number of frames dropped. In recorded streaming or progressive cases, if the video is a high quality or a high resolution, high bit-rate video, the decoder may lag behind in decoding the required number of frames per second if it does not have adequate system resources (CPU). In the live streaming case, it is possible that queue has to drop frames to catch up if the latency is getting high. The droppedFrames property would provide useful information in such cases, specifying the number of frames which were dropped and not presented to the video object. Hence this property is very useful in determining whether the client has enough CPU to display a video of a particular bit rate or resolution, or otherwise switch to a lower quality or resolution stream.
This property could also be used during the video encoding stage to test the compression or resolution values by tracking the dropped frame count or rate at different target platforms and make sure the numbers stay low, or otherwise encode the video at lower resolutions. For a publishing stream, droppedFrames would provide the frames dropped from publishing due to limited CPU or network resources.

The above properties are computed both for receiving and publishing NetStream instances as well as publishing Camera and Microphone data, unless otherwise noted.

playbackBytesPerSecond: The current NetStream playback rate in bytes per second. The playback buffer could have various playlists buffered in it. With multi-bit-rate switching, this would happen more frequently now. This property would provide the bit rate at which the current video is playing.
audioBufferByteLength, videoBufferByteLength, dataBufferByteLength: The NetStream buffer size in bytes. Similar to NetStream.bytesLoaded that is used in progressive cases, these properties specify the size in bytes in the buffer for audio, video, and data, respectively. This provides raw buffer size information for streaming both live and recorded streams.
audioBufferLength, videoBufferLength, dataBufferLength: The NetStream buffer size in units of time. These calls extend the bufferLength property, which exists in NetStream already, to provide the buffer length in time values for audio, video, and data, respectively.
SRTT: Session Round Trip Time. Provides a smoothened value of the round trip time of the NetStream session (averaged over a number of round trips between the client and server or two clients). This returns a valid value only for RTMFP streams; it returns 0 for RTMP streams.


// old
audioBufferByteLength: Provides the NetStream audio buffer size in bytes.
audioBufferLength: Provides NetStream audio buffer size in seconds.
audioByteCount: Specifies the total number of audio bytes that have arrived in the queue, regardless of how many have been played or flushed.
audioBytesPerSecond: Specifies the rate at which the NetStream audio buffer is filled in bytes per second.
audioLossRate: Specifies the audio loss for the NetStream session.
byteCount: Specifies the total number of bytes that have arrived into the queue, regardless of how many have been played or flushed.
currentBytesPerSecond: Specifies the rate at which the NetStream buffer is filled in bytes per second.
dataBufferByteLength: Provides the NetStream data buffer size in bytes.
dataBufferLength: Provides the NetStream data buffer size in seconds.
dataByteCount: Specifies the total number of bytes of data messages that have arrived in the queue, regardless of how many have been played or flushed.
dataBytesPerSecond: Specifies the rate at which the NetStream data buffer is filled in bytes per second.
droppedFrames: Returns the number of video frames dropped in the current NetStream playback session.
maxBytesPerSecond: Specifies the maximum rate at which the NetStream buffer is filled in bytes per second.
playbackBytesPerSecond: Returns the stream playback rate in bytes per second.
SRTT: Specifies the Smooth Round Trip Time for the NetStream session.
videoBufferByteLength: Provides the NetStream video buffer size in bytes.
videoBufferLength: Provides the NetStream video buffer size in seconds.
videoByteCount: Specifies the total number of video bytes that have arrived in the queue, regardless of how many have been played or flushed.
videoBytesPerSecond: Specifies the rate at which the NetStream video buffer is filled in bytes per second.
*/



/*************** NetStream event/.client handlers ******************/

private function netStreamStatusEventHandler(event:NetStatusEvent):void
{
	debugMsg("netStreamStatusEventHandler->  code: "+event.info.code);
	
	var code:String = event.info.code;
	switch (code)
	{
		case "NetStream.Play.Start" :
			// playback has started
			break;
		case "NetStream.Play.Stop" :
			// playback has stopped
			break;
		case "NetStream.Play.StreamNotFound" :
			// usually means bad streamName.. create an error alert for the user
			break;
		case "NetStream.Play.Complete" :
			// VOD video has ended
			break;
		case "NetStream.Play.PublishNotify" : // someone is now publishing to the NetStream
			break;
		case "NetStream.Play.UnpublishNotify" : // someone has unpublished the NetStream
			break;
		case "NetStream.Play.Reset" :
			break;
		case "NetStream.Video.DimensionChange" :
			//debugMsg("netStreamStatusEventHandler->  <NetStream.Video.DimensionChange>  "/* + __camSpot_NS.info.toString()*/);
			break;
		case "NetStream.Seek.Notify" :
			break;
		case "NetStream.Play.InsufficientBW" :
			debugMsg("netStreamStatusEventHandler->  <NetStream.Play.InsufficientBW>"+
				"\n\t\t\t\t\t\t\t\t\t\t\tbytesTotal: "+__camSpot_NS.bytesTotal+
				"\n\t\t\t\t\t\t\t\t\t\t\tbytesLoaded: "+__camSpot_NS.bytesLoaded+
				"\n\t\t\t\t\t\t\t\t\t\t\tbuffer: "+Math.floor((__camSpot_NS.bufferTime / __camSpot_NS.bufferLength) * 100)+
				//"\n\t\t\t\t\t\t\t\t\t\t\tbuffer: "+((__camSpot_NS.bufferTime / __camSpot_NS.bufferLength) * 100)+
				"\n\t\t\t\t\t\t\t\t\t\t\tbufferTime: "+__camSpot_NS.bufferTime+
				"\n\t\t\t\t\t\t\t\t\t\t\tbufferTimeMax: "+__camSpot_NS.bufferTimeMax+
				"\n\t\t\t\t\t\t\t\t\t\t\tbackBufferTime: "+__camSpot_NS.backBufferTime+
				"\n\t\t\t\t\t\t\t\t\t\t\tmaxPauseBufferTime: "+__camSpot_NS.maxPauseBufferTime+
				"\n\t\t\t\t\t\t\t\t\t\t\tbufferLength: "+__camSpot_NS.bufferLength+
				"\n\t\t\t\t\t\t\t\t\t\t\tbackBufferLength: "+__camSpot_NS.backBufferLength+
				"\n\t\t\t\t\t\t\t\t\t\t\tuseJitterBuffer: "+__camSpot_NS.useJitterBuffer+
				"\n\t\t\t\t\t\t\t\t\t\t\tinBufferSeek: "+__camSpot_NS.inBufferSeek+
				"\n\t\t\t\t\t\t\t\t\t\t\tliveDelay: "+__camSpot_NS.liveDelay+
				"\n\t\t\t\t\t\t\t\t\t\t\tnsBandwidthDelayProduct: "+Math.floor(__camSpot_NS.info.currentBytesPerSecond * __camSpot_NS.liveDelay)+
				"\n\t\t\t\t\t\t\t\t\t\t\tvideoBufferLength: "+__camSpot_NS.info.videoBufferLength+
				"\n\t\t\t\t\t\t\t\t\t\t\taudioBufferLength: "+__camSpot_NS.info.audioBufferLength+
				"\n\t\t\t\t\t\t\t\t\t\t\tcurrentBytesPerSecond: "+__camSpot_NS.info.currentBytesPerSecond+
				"\n\t\t\t\t\t\t\t\t\t\t\tplaybackBytesPerSecond: "+__camSpot_NS.info.playbackBytesPerSecond+
				"\n\t\t\t\t\t\t\t\t\t\t\tmaxBytesPerSecond: "+__camSpot_NS.info.maxBytesPerSecond+
				//"\n\t\t\t\t\t\t\t\t\t\t\t: "+__camSpot_NS+
				//"\n\t\t\t\t\t\t\t\t\t\t\tNetStreamInfo: "+__camSpot_NS.info.toString()+
				"\n\n");
			
			// TODO: auto-adjust for currently available bandwidth
			break;
		default :
			debugMsg("netStreamStatusEventHandler->  UNHANDLED CASE: "+event.info.code);
			break;
	}
	
	event.stopPropagation();
	
	event = null;
}


private function netStreamAsyncErrorHandler(event:AsyncErrorEvent):void
{ 
	debugMsg("netStreamAsyncErrorHandler->  errorID: "+event.errorID+"  error: "+event.error+"  text: "+event.text);
	
	event.stopPropagation();
	
	event = null;
}


private function netStreamIOErrorHandler(event:*):void
{ 
	debugMsg("netStreamIOErrorHandler->  errorID: "+event.errorID+"  error: "+event.error+"  text: "+event.text);
	
	event.stopPropagation();
	
	event = null;
}


private function netStreamSecurityError(event:*):void
{ 
	debugMsg("netStreamSecurityError->  errorID: "+event.errorID+"  error: "+event.error+"  text: "+event.text);
	
	event.stopPropagation();
	
	event = null;
}



public function onFCSubscribe(infoObj:Object):void
{
	debugMsg("onFCSubscribe->  infoObj: "+infoObj);
	
	infoObj = null;
}


public function onPeerConnect(subscriber:NetStream):void
{
	debugMsg("onPeerConnect->  subscriber: "+subscriber);
	
	subscriber = null;
}


private function onPlayStatus(infoObj:Object):void
{
	// check if infoObj is not null
	if (!infoObj) return;
	
	debugMsg("onPlayStatus->  code: "+infoObj.code);
	
	if (infoObj.code == "NetStream.Play.Complete")
	{
		// VOD video has ended
	}
	
	// trace debug info
	for (var i:* in infoObj)
	{
		debugMsg("onPlayStatus->\t"+i+": "+infoObj[i]);
	}
	
	infoObj = null;
}


// TODO: use only static data,
// which is not changed after being received.
// TODO: separate the subscriber specific stats.
public function onMetaData(infoObj:Object):void
{
	// check if infoObj is not null
	if (!infoObj) return;
	
	// set this camSpot users` MetaData...
	userMetaData = infoObj;
	
	// add extra data not sent by the user.
	userMetaData.camSpotID = this.id;
	userMetaData.inBufferSeek = __camSpot_NS.inBufferSeek;
	userMetaData.useJitterBuffer = __camSpot_NS.useJitterBuffer;
	userMetaData.maxPauseBufferTime = __camSpot_NS.maxPauseBufferTime;
	userMetaData.backBufferTime = __camSpot_NS.backBufferTime;
	userMetaData.backBufferLength = __camSpot_NS.backBufferLength;
	userMetaData.bufferTimeMax = __camSpot_NS.bufferTimeMax;
	userMetaData.bufferTime = __camSpot_NS.bufferTime;
	userMetaData.bufferLength = __camSpot_NS.bufferLength;
	userMetaData.liveDelay = __camSpot_NS.liveDelay;
	userMetaData.nsBandwidthDelayProduct = (__camSpot_NS.info.currentBytesPerSecond * __camSpot_NS.liveDelay);
	userMetaData.useHardwareDecoder = __camSpot_NS.useHardwareDecoder;
	
	//debugMsg("onMetaData->  userMetaData: "+userMetaData+"  camSpot_NS: "+__camSpot_NS+"  videoStreamSettings: "+__camSpot_NS.videoStreamSettings+"  netStreamInfo: "+__camSpot_NS.info);
	//debugMsg("onMetaData->\t<propertyIsEnumerable>\t\tuserMetaData: "+this.propertyIsEnumerable(userMetaData)+"  camSpot_NS: "+this.propertyIsEnumerable(__camSpot_NS)+"  videoStreamSettings: "+__camSpot_NS.propertyIsEnumerable('videoStreamSettings')+"  netStreamInfo: "+__camSpot_NS.propertyIsEnumerable('info'));
	
	// debug
	for (var i:* in userMetaData)
		debugMsg("onMetaData->\t\t"+i+" = "+userMetaData[i]);
	/*
	for (var x:* in __camSpot_NS)
	debugMsg("onMetaData->\t<NetStream>\t\t"+x+": "+__camSpot_NS[x]);
	
	for (var y:* in __camSpot_NS.videoStreamSettings)
	debugMsg("onMetaData->\t<NetStream.videoStreamSettings>\t\t"+y+": "+__camSpot_NS.videoStreamSettings[y]);
	
	for (var z:* in __camSpot_NS.info)
	debugMsg("onMetaData->\t<NetStream.info>\t\t"+z+": "+__camSpot_NS.info[z]);
	
	if (__camSpot_NS.multicastInfo)
	{
	for (z in __camSpot_NS.multicastInfo)
	debugMsg("onMetaData->\t<NetStream.multicastInfo>\t\t"+z+": "+__camSpot_NS.multicastInfo[z]);
	}
	
	z = null;
	y = null;
	x = null;
	*/
	i = null;
	
	infoObj = null;
}


public function onTextData(infoObj:Object):void
{
	// check if infoObj is not null
	if (!infoObj) return;
	
	// trace debug info
	for (var i:String in infoObj)
	{
		debugMsg("onTextData->\t"+i+": "+infoObj[i]);
	}
	
	infoObj = null;
}


public function onXMPData(infoObj:Object):void
{
	// check if infoObj is not null
	if (!infoObj) return;
	
	// trace debug info
	for (var i:String in infoObj)
	{
		debugMsg("onXMPData->\t"+i+": "+infoObj[i]);
	}
	
	infoObj = null;
}


public function onFI(infoObj:Object):void
{
	// check if infoObj is not null
	if (!infoObj) return;
	
	var timecode:String;
	for (var i:String in infoObj)
	{
		if (i == "tc")
		{
			timecode = infoObj.tc; // string formatted HH:MM:SS:FF
		}
	}
	
	infoObj = null;
}










private function debugMsg(str:String):void
{
	AppWideDebug_Singleton.getInstance().newDebugMessage(this.id, str);
	
	str = null;
}


