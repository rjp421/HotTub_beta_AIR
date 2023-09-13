package me.whohacked.app
{
	
	//import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.net.Responder;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	import events.CustomEvent;
	
	import org.apache.flex.collections.ArrayList;
	
	import scripts.net.NetConnectionClient;
	import scripts.net.NetConnectionManager;
	
	
	
	public class AppWide_Singleton
	{
		
		
		private static var __instance:AppWide_Singleton;
		private var __initialized:Boolean;
		private var __clientGetStats_Responder:Responder;
		private var __appWideEventDispatcher:AppWideEventDispatcher_Singleton;
		
		
		// version 4, date 09-13-2023, build 01
		public var version:Number = 40913202301;
		public var debugMode:Boolean = false;
		
		public var flashVars:Object;
		public var statsTimer:Timer;
		
		public var loggedOut:Boolean = true; // used for auto-reconnect
		public var localNetConnection:NetConnectionManager;
		public var localCamera:Camera;
		public var localMic:Microphone;
		
		public var appInfoObj:Object;
		public var userInfoObj:Object;
		public var compatibilityInfoObj:Object;
		public var clientStatsInfoObj:Object;
		
		public var openPopUps_AC:ArrayCollection;
		public var dockedUserIDs_AC:ArrayCollection;
		public var userList_AC:ArrayCollection;
		public var usersWithVideoOn_A:Array;
		
		public var camSpotIDs_A:Array;
		public var largeCamIDs_A:Array;
		public var backgroundCamSpotIDs_A:Array;
		public var numVisibleCamSpots:Number;
		public var numTotalCamSpots:Number;
		
		public var previousClientIDs_A:Array;
		
		
		
		public function AppWide_Singleton()
		{
			if (__instance)
				throw new Error("AppWide_Singleton is a singleton class, use .getInstance() instead!");
			
			// en/disable debugMode
			var _awd:AppWideDebug_Singleton = AppWideDebug_Singleton.getInstance();
			_awd.debugMode = this.debugMode;
			_awd.chatDebugMode = false;
			_awd = null;
			
			init(); // instantiate the initial components
		}
		
		
		private function init():void // instantiate the static variables
		{
			if (!__initialized) // if this Singleton has not been instantiated yet
			{
				__initialized = true; // the class has now been instantiated
			}
			
			userList_AC = new ArrayCollection();
			userList_AC.enableAutoUpdate();
			
			openPopUps_AC = new ArrayCollection();
			dockedUserIDs_AC = new ArrayCollection();
			
			camSpotIDs_A = [];
			largeCamIDs_A = [];
			backgroundCamSpotIDs_A = [];
			
			usersWithVideoOn_A = [];
			
			numVisibleCamSpots = 0;
			numTotalCamSpots = 0;
			
			localCamera = null;
			localMic = null;
			
			// TODO: auto-reconnect.
			// set up the NetConnection
			localNetConnection = new NetConnectionManager();
			localNetConnection.client = new NetConnectionClient();
			
			statsTimer = new Timer(1000, 0);
			statsTimer.addEventListener(TimerEvent.TIMER, onStatsTimerTickHandler, false,0,true);
			
			__clientGetStats_Responder = new Responder(onClientGetStatsResponder);
			
			userInfoObj = {};
			userInfoObj.clientID = 0;
			userInfoObj.acctID = 0;
			userInfoObj.acctName = '';
			userInfoObj.userID = 0;
			userInfoObj.userName = '';
			userInfoObj.adminType = 'notadmin';
			userInfoObj.isMyVideoOn = false;
			userInfoObj.isMyAudioOn = false;
			userInfoObj.isMediaPrivate = false;
			userInfoObj.viewedByUserIDs_A = [];
			userInfoObj.heardByUserIDs_A = [];
			//userInfoObj.ignores = {names:{}, acctids:{}};
			userInfoObj.ignores = {};
			
			appInfoObj = {};
			appInfoObj.login = "";
			appInfoObj.pass = "";
			appInfoObj.defaultQuality = "hd";
			appInfoObj.version = this.version;
			appInfoObj.debugMode = this.debugMode;
			appInfoObj.chatDebugMode = false;
			appInfoObj.selectedConnectionProtocol = "rtmp";
			appInfoObj.selectedLayout = "medium";
			appInfoObj.selectedCameraName = "";
			appInfoObj.selectedCameraInputSize = "320x240";
			appInfoObj.selectedMicrophoneName = "Default";
			appInfoObj.selectedVideoCodec = "sorenson"; // sorenson, or h264
			appInfoObj.selectedAudioCodec = "nellymoser"; // nellymoser (default) or speex
			appInfoObj.showBWChart = true;
			appInfoObj.showCamSpotStats = false;
			appInfoObj.isUseOthersQualityChecked = false;
			appInfoObj.isSavePasswordChecked = false;
			appInfoObj.isAllFontSizeChecked = false;
			appInfoObj.isAutoFillCamsChecked = true;
			appInfoObj.isAllCamsOffChecked = false;
			appInfoObj.isAllAudioOffChecked = true; // true
			appInfoObj.isVoiceChatEnabled = false;
			appInfoObj.isAutoReconnectEnabled = true;
			appInfoObj.isAutoAdjustForBWEnabled = true;
			appInfoObj.isRoomHostOnMainChecked = true; // true
			appInfoObj.isUnmuteRoomHostChecked = true; // false
			appInfoObj.isShowTimestampsChecked = true; // false
			appInfoObj.isPrivateMessageEnabledChecked = true;
			appInfoObj.isPrivateMessageInNewWindowChecked = true;
			appInfoObj.isBanned = false;
			appInfoObj.fontBold = false;
			appInfoObj.fontItalics = false;
			appInfoObj.fontUnderline = false;
			appInfoObj.fontColor = 000000;
			appInfoObj.fontSize = 14;
			appInfoObj.currentHostUserID = 0; // 0 if no host, otherwise hosts userID
			
			__appWideEventDispatcher = AppWideEventDispatcher_Singleton.getInstance();
			__appWideEventDispatcher.addEventListener('onApplicationComplete', onApplicationComplete, false,0,true);
			__appWideEventDispatcher.addEventListener('appClose', onAppClose, false,0,true);
			__appWideEventDispatcher.addEventListener('openFlashSettings', onOpenFlashSettingsHandler, false,0,true);
			
			// TODO, not used atm, move to video settings
			//__appWideEventDispatcher.addEventListener('takeProfileSnapshot', takeProfileSnapshot, false,0,true);
			
			compatibilityInfoObj = {};
			
			previousClientIDs_A = [];
		}
		
		
		private function onApplicationComplete(event:Event):void
		{
			var localSOManager:LocalSOManager_Singleton = LocalSOManager_Singleton.getInstance();
			
			debugMsg("onApplicationComplete->  isLocalSOAllowed: " + localSOManager.isLocalSOAllowed);
			
			// update the app info object with any saved settings
			if (localSOManager.isLocalSOAllowed)
			{
				setAppInfo("login", localSOManager.getLocalSOProperty('login'));
				setAppInfo("pass", localSOManager.getLocalSOProperty('pass'));
				
				//setAppInfo("chatDebugMode", false); // TODO
				setAppInfo("isBanned", localSOManager.getLocalSOProperty('isBanned'));
				setAppInfo("defaultQuality", localSOManager.getLocalSOProperty('defaultQuality'));
				
				setAppInfo("isSavePasswordChecked", localSOManager.getLocalSOProperty('isSavePasswordChecked'));
				setAppInfo("isAllFontSizeChecked", localSOManager.getLocalSOProperty('isAllFontSizeChecked'));
				
				setAppInfo("isAutoFillCamsChecked", localSOManager.getLocalSOProperty('isAutoFillCamsChecked'));
				setAppInfo("isAllCamsOffChecked", localSOManager.getLocalSOProperty('isAllCamsOffChecked'));
				setAppInfo("isAllAudioOffChecked", localSOManager.getLocalSOProperty('isAllAudioOffChecked'));
				
				setAppInfo("isVoiceChatEnabled", localSOManager.getLocalSOProperty('isVoiceChatEnabled'));
				
				setAppInfo("isRoomHostOnMainChecked", localSOManager.getLocalSOProperty('isRoomHostOnMainChecked'));
				setAppInfo("isUnmuteRoomHostChecked", localSOManager.getLocalSOProperty('isUnmuteRoomHostChecked'));
				setAppInfo("isShowTimestampsChecked", localSOManager.getLocalSOProperty('isShowTimestampsChecked'));
				
				setAppInfo("isUseOthersQualityChecked", localSOManager.getLocalSOProperty('isUseOthersQualityChecked'));
				
				setAppInfo("fontSize", localSOManager.getLocalSOProperty('fontSize'));
				setAppInfo("fontColor", localSOManager.getLocalSOProperty('fontColor'));
				setAppInfo("fontBold", localSOManager.getLocalSOProperty('fontBold'));
				setAppInfo("fontItalics", localSOManager.getLocalSOProperty('fontItalics'));
				setAppInfo("fontUnderline", localSOManager.getLocalSOProperty('fontUnderline'));
				
				// set defaults on possibly new/missing settings
				if ((localSOManager.getLocalSOProperty('selectedLayout') != null) &&
					(localSOManager.getLocalSOProperty('selectedLayout') != undefined))
					setAppInfo("selectedLayout", localSOManager.getLocalSOProperty('selectedLayout'));
				
				if ((localSOManager.getLocalSOProperty('selectedCameraName') != null) &&
					(localSOManager.getLocalSOProperty('selectedCameraName') != undefined))
					setAppInfo("selectedCameraName", localSOManager.getLocalSOProperty('selectedCameraName'));
				
				if ((localSOManager.getLocalSOProperty('selectedCameraInputSize') != null) &&
					(localSOManager.getLocalSOProperty('selectedCameraInputSize') != undefined))
					setAppInfo("selectedCameraInputSize", localSOManager.getLocalSOProperty('selectedCameraInputSize'));
				
				if ((localSOManager.getLocalSOProperty('selectedMicrophoneName') != null) &&
					(localSOManager.getLocalSOProperty('selectedMicrophoneName') != undefined))
					setAppInfo("selectedMicrophoneName", localSOManager.getLocalSOProperty('selectedMicrophoneName'));
				
				if ((localSOManager.getLocalSOProperty('selectedVideoCodec') != null) &&
					(localSOManager.getLocalSOProperty('selectedVideoCodec') != undefined))
					setAppInfo("selectedVideoCodec", localSOManager.getLocalSOProperty('selectedVideoCodec'));
				if ((localSOManager.getLocalSOProperty('selectedAudioCodec') != null) &&
					(localSOManager.getLocalSOProperty('selectedAudioCodec') != undefined))
					setAppInfo("selectedAudioCodec", localSOManager.getLocalSOProperty('selectedAudioCodec'));
				
				if ((localSOManager.getLocalSOProperty('showBWChart') != null) &&
					(localSOManager.getLocalSOProperty('showBWChart') != undefined))
					setAppInfo("showBWChart", localSOManager.getLocalSOProperty('showBWChart'));
				if ((localSOManager.getLocalSOProperty('showCamSpotStats') != null) &&
					(localSOManager.getLocalSOProperty('showCamSpotStats') != undefined))
					setAppInfo("showCamSpotStats", localSOManager.getLocalSOProperty('showCamSpotStats'));
				
				if ((localSOManager.getLocalSOProperty('isAutoReconnectEnabled') != null) &&
					(localSOManager.getLocalSOProperty('isAutoReconnectEnabled') != undefined))
					setAppInfo("isAutoReconnectEnabled", localSOManager.getLocalSOProperty('isAutoReconnectEnabled'));
				if ((localSOManager.getLocalSOProperty('isAutoAdjustForBWEnabled') != null) &&
					(localSOManager.getLocalSOProperty('isAutoAdjustForBWEnabled') != undefined))
					setAppInfo("isAutoAdjustForBWEnabled", localSOManager.getLocalSOProperty('isAutoAdjustForBWEnabled'));
			}
			
			event = null;
		}
		
		
		private function onApplicationStateChange(event:Event):void
		{
			debugMsg("onApplicationStateChange->  applicationState: "+appInfoObj.applicationState);
			
			event = null;
		}
		
		
		public function setAppInfo(arg:String, val:*):void
		{
			debugMsg("setAppInfo->  " +  arg + " = " + val);
			
			var tmpArr:ArrayList;
			
			appInfoObj[arg] = val;
			
			LocalSOManager_Singleton.getInstance().setLocalSOProperty(arg, val);
			
			if (arg == 'debugMode')
			{
				debugMode = val;
				AppWideDebug_Singleton.getInstance().debugMode = val;
			} else if (arg == 'chatDebugMode') {
				AppWideDebug_Singleton.getInstance().chatDebugMode = val;
			} else if (arg == 'selectedCameraName') {
				// TODO:
				// pause any current publishing, and update the current NetStream
				// with the new devices/settings.
				
				// this function is called after the Flash Player settings
				// window has been closed, and expects the user to have chosen
				// their chosen devices. 
				// Currently it only gets the current settings.
				
				var _selectedCameraName:String = appInfoObj.selectedCameraName; // use the currently selected camera name
				var _selectedCamIndex:int = Camera.names.indexOf(_selectedCameraName);
				
				this.localCamera = Camera.getCamera(String(_selectedCamIndex));

				debugMsg("setAppInfo->  <localCamera>  "+this.localCamera+"  selectedCamIndex: "+_selectedCamIndex+"  selectedCameraName: "+_selectedCameraName);
				
				// TODO bad
				// does not set the Camera.getCamera to the previously chosen devices yet.
				// for now just selected them manually.
				/*
				// check which camera matches the name? still bad
				tmpArr = new ArrayList(Camera.names);
				
				for (var i:int = 0; i < tmpArr.length; ++i) 
				{
					var cameraName:String = _selectedCameraName ? tmpArr.getItemAt(i) as String : '';
					
					if ((tmpArr.length) &&
						(cameraName == val) &&
						(Camera.getCamera(_selectedCamIndex as String)))
					{
						//localCamera = Camera.getCamera(selectedCameraName ? i as String : '');
						this.localCamera = Camera.getCamera(_selectedCamIndex as String);
						
						debugMsg("setAppInfo->  <localCamera>  "+this.localCamera+"  cameraName: "+cameraName+"  selectedCameraName: "+_selectedCameraName);

						break; // exit if camera found
					} else { 
						// if not publishing
						//__instance.localCamera = null;
					}
					
					cameraName = null;
				}
				*/
				_selectedCameraName = null;
				//_selectedCamIndex = null;
			} else if (arg == 'selectedMicrophoneName') {
				var selectedMicrophoneName:String = appInfoObj.selectedMicrophoneName;
				var selectedMicIndex:int = Microphone.names.indexOf(selectedMicrophoneName);
				tmpArr = new ArrayList(Microphone.names);
				
				for (var x:int = 0; x < tmpArr.length; ++x) 
				{
					var microphoneName:String = tmpArr.getItemAt(x) as String;
					
					// TODO use getEnhancedMicrophone if speex is currently chosen
					if ((tmpArr.length) &&
						(microphoneName == val) &&
						(Microphone.getMicrophone(x)))
					{
						localMic = Microphone.getMicrophone(x);
						
						debugMsg("setAppInfo->  <localMic>  "+localMic+"  microphoneName: "+microphoneName);
					}
					
					microphoneName = null;
				}
				
			}
			
			tmpArr = null;
			val = null;
			arg = null;
		}
		
		
		public function setCompatibilityInfo(arg:String, val:*):void
		{
			debugMsg("setCompatibilityInfo->  " +  arg + " = " + val);
			
			compatibilityInfoObj[arg] = val;
			
			val = null;
			arg = null;
		}
		
		
		public static function getInstance():AppWide_Singleton
		{
			if (__instance==null)
			{
				__instance = new AppWide_Singleton();
			}
			
			return __instance;
		}
		
		
		public static function getLocalCamera():Camera
		{
			if (__instance==null)
			{
				__instance = new AppWide_Singleton();
			}
			
			if (!__instance.localCamera)
			{
				if (__instance.appInfoObj.selectedCameraName.length)
				{
					var _selectedCameraName:String = __instance.appInfoObj.selectedCameraName; // use the currently selected camera name
					var _selectedCamIndex:int = Camera.names.indexOf(_selectedCameraName);
					
					__instance.localCamera = Camera.getCamera(String(_selectedCamIndex));
					_selectedCameraName = null;
				} else {
					__instance.localCamera = Camera.getCamera();
				}
			}

			return __instance.localCamera;
		}
		
		
		public static function getLocalMic():Microphone
		{
			if (__instance==null)
			{
				__instance = new AppWide_Singleton();
			}

			return __instance.localMic;
		}
		
		
		public static function getAppInfoObj():Object
		{
			if (__instance==null)
			{
				__instance = new AppWide_Singleton();
			}
			
			return __instance.appInfoObj;
		}
		
		
		public static function getUserInfoObj():Object
		{
			if (__instance==null)
			{
				__instance = new AppWide_Singleton();
			}
			
			return __instance.userInfoObj;
		}
		
		
		public static function getUserList_AC():ArrayCollection
		{
			if (__instance==null)
			{
				__instance = new AppWide_Singleton();
			}
			
			return __instance.userList_AC;
		}
		
		
		// TODO
		public function getUserObj():Object
		{
			var x:Object = {};
			return x;
		}
		
		// TODO
		private function setCamera():void
		{
		}

		
		private function onOpenFlashSettingsHandler(event:CustomEvent):void
		{
			var device:String = event.eventObj.device.toString().toLowerCase();
			
			if (!device)
				Security.showSettings(SecurityPanel.PRIVACY);
			
			if (device.indexOf('cam') != -1)
				Security.showSettings(SecurityPanel.CAMERA);
			
			if (device.toLowerCase().indexOf('mic') != -1)
				Security.showSettings(SecurityPanel.MICROPHONE);
			
			device = null;
			event = null;
		}
		
		
		private function onStatsTimerTickHandler(event:TimerEvent):void
		{
			if ((localNetConnection) && 
				(localNetConnection.connected))
			{
				localNetConnection.call("getStats", __clientGetStats_Responder);
			} else {
				if (statsTimer.running)
					statsTimer.stop();
				clientStatsInfoObj = {};
			}
			
			event = null;
		}
		
		
		private function onClientGetStatsResponder(resultObj:Object):void
		{
			clientStatsInfoObj = resultObj;
			clientStatsInfoObj.connectionDuration = statsTimer.currentCount;
			
			__appWideEventDispatcher.dispatchEvent(new Event("onClientGetStats"));
			
			/*
			debugMsg("onClientGetStatsResponder->  resultObj: " + resultObj);
			
			for (var i:String in resultObj)
			{
				debugMsg("onClientGetStatsResponder->\t\t" + i + ": " + resultObj[i]);
			}
			
			i = null;
			*/
			resultObj = null;
		}
		
		
		private function onUserLoggedIn():void
		{
			debugMsg("onUserLoggedIn->  ");
			
		}
		
		
		private function beginLogout():void
		{
			debugMsg("beginLogout->  ");
			
			if (statsTimer.running)
				statsTimer.stop();
		}
		
		
		private function onAppClose(event:Event):void
		{
			debugMsg("onAppClose->  ");
			
			if (statsTimer.running)
				statsTimer.stop();
			
			// clear the dockedUserIDs_A
			dockedUserIDs_AC.removeAll();
			
			// clear the user list
			userList_AC.removeAll();
			
			// reset the userInfoObj
			userInfoObj.clientID = 0;
			userInfoObj.acctID = 0;
			userInfoObj.acctName = '';
			userInfoObj.userID = 0;
			userInfoObj.userName = '';
			userInfoObj.adminType = 'notadmin';
			userInfoObj.isMyVideoOn = false;
			userInfoObj.isMyAudioOn = false;
			userInfoObj.isMediaPrivate = false;
			//userInfoObj.ignores = {names:{}, acctids:{}};
			userInfoObj.ignores = {};
			userInfoObj.viewedByUserIDs_A.splice(0, userInfoObj.viewedByUserIDs_A.length);
			userInfoObj.heardByUserIDs_A.splice(0, userInfoObj.heardByUserIDs_A.length);
		}
		
		
		
		
		// TODO
		// test example of how to create a snapshot and send to the server
		// and save it server-side as a JPG for their profile pic
		/*private function takeProfileSnapshot(event:CustomEvent):void
		{
			var previewVideo:Video = event.eventObj.previewVideo;
			var bmd:BitmapData = new BitmapData(previewVideo.width, previewVideo.height, true);
			bmd.draw(previewVideo);
			var jpgEncoder:JPEGEncoder = new JPEGEncoder(89);
			var jpgStream:ByteArray = jpgEncoder.encode(bmd);
			var streamName:String = "previewThumb";
			
			// capture the frame from the users preview
			localNetConnection.call("mediaManager.createThumb", null, jpgStream, streamName);
		}
		*/
		
		
		
		
		
		
		
		
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			AppWideDebug_Singleton.getInstance().newDebugMessage('AppWideSingleton', str);
			
			str = null;
		}
		
		
		
		
		
	} // end class
} // end package