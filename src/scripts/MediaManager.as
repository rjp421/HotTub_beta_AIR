/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
package scripts
{
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SampleDataEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.H264Level;
	import flash.media.H264Profile;
	import flash.media.H264VideoStreamSettings;
	import flash.media.Microphone;
	import flash.media.MicrophoneEnhancedMode;
	import flash.media.MicrophoneEnhancedOptions;
	import flash.media.SoundCodec;
	import flash.net.NetStream;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	import spark.primitives.BitmapImage;
	
	import events.CustomEvent;
	
	import me.whohacked.app.AppWideDebug_Singleton;
	import me.whohacked.app.AppWideEventDispatcher_Singleton;
	import me.whohacked.app.AppWide_Singleton;
	import me.whohacked.app.LocalSOManager_Singleton;
	
	import scripts.net.NetConnectionManager;
	
	
	public class MediaManager
	{
		
		private var __nc:NetConnectionManager;
		private var __localNetStream:NetStream;
		private var __h264Settings:H264VideoStreamSettings;
		private var __mediaSO:SharedObject;
		
		//public var mediaSOClient:MediaSOClient;
		
		public var clientID:String;
		public var acctID:Number;
		public var acctName:String;
		public var userID:Number;
		public var userName:String;
		public var isMyVideoOn:Boolean;
		public var isMyAudioOn:Boolean;
		public var isMediaPrivate:Boolean;
		public var myMetaData:Object;
		public var camera:Camera;
		public var mic:Microphone;
		public var viewedByUserIDs_A:Array;
		public var heardByUserIDs_A:Array;
		public var micVolumeActivityTimer:Timer;
		public var localUserAudioInputVolumeMeter:BitmapImage;
		
		
		
		public function MediaManager()
		{
			debugMsg("->  LOADED");
			
			var __appWideSingleton:AppWide_Singleton = AppWide_Singleton.getInstance();
			
			__nc = __appWideSingleton.localNetConnection;
			
			//mediaSOClient = new MediaSOClient();
			
			viewedByUserIDs_A = __appWideSingleton.userInfoObj.viewedByUserIDs_A;
			heardByUserIDs_A = __appWideSingleton.userInfoObj.heardByUserIDs_A;
			
			isMyVideoOn = false;
			isMyAudioOn = false;
			isMediaPrivate = false;
			camera = null;
			mic = null;
			
			__appWideSingleton = null;
		}
		
		
		public function get localNetStream():NetStream
		{
			return __localNetStream;
		}
		
		
		public function initMediaManager():void
		{
			myMetaData = {};
			
			// initializes only,
			// does not publish or attachCamera/Mic
			setupNetStream();
			
			var userInfoObj:Object = AppWide_Singleton.getUserInfoObj();
			
			clientID = userInfoObj.clientID;
			acctID = userInfoObj.acctID;
			userID = userInfoObj.userID;
			userName = userInfoObj.userName;
			//roomName = userInfoObj.roomName;
			
			//__mediaSO = SharedObject.getRemote("media", __nc.uri, false);
			//__mediaSO.client = mediaSOClient;
			//__mediaSO.connect(__nc);
			
			userInfoObj = null;
		}
		
		
		
		
		private function setupNetStream():void
		{
			debugMsg("setupNetStream->  localNetStream: "+(__localNetStream?__localNetStream:""));
			
			if (!__localNetStream)
			{
				// do not create a new NetStream unless the NetConnection is already connected
				if (!__nc.connected) return;
				
				// create/connect the NetStream if it hasnt been created yet
				__localNetStream = new NetStream(__nc);
				
				// set the NetStreams client to this so this class will handle function calls over the NetStream
				__localNetStream.client = this;
				
				// listen for NetStatusEvents on the NetStream
				if (!__localNetStream.hasEventListener(NetStatusEvent.NET_STATUS)) { __localNetStream.addEventListener(NetStatusEvent.NET_STATUS, localNetStreamStatusEventHandler, false,0,true); }
				if (!__localNetStream.hasEventListener(IOErrorEvent.NETWORK_ERROR)) { __localNetStream.addEventListener(IOErrorEvent.NETWORK_ERROR, localNetStreamIOErrorHandler, false,0,true); }
				if (!__localNetStream.hasEventListener(AsyncErrorEvent.ASYNC_ERROR)) { __localNetStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, localNetStreamAsyncErrorHandler, false,0,true); }
				if (!__localNetStream.hasEventListener(SecurityErrorEvent.SECURITY_ERROR)) { __localNetStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, localNetStreamSecurityError, false,0,true); }
				
				// TODO
				// move to setupNetStream.
				// set rtmfp specific properties for the publishers NetStream
				if (AppWide_Singleton.getAppInfoObj().selectedConnectionProtocol == "rtmfp")
				{
					__localNetStream.dataReliable = false;
					__localNetStream.videoReliable = false;
					__localNetStream.audioReliable = false;
					//__localNetStream.client.onPeerConnect = function(subscriber:NetStream):Boolean { subscriber = null; return true; };
				} else {
					__localNetStream.dataReliable = true;
					__localNetStream.videoReliable = true;
					__localNetStream.audioReliable = true;
					//delete __localNetStream.client.onPeerConnect;
					//__localNetStream.client.onPeerConnect = null;
				}
				
				// set the LIVE buffer (no buffering),
				// not working (when defined here)?!
				__localNetStream.useJitterBuffer = true;
				__localNetStream.bufferTime = 0.000;
				__localNetStream.bufferTimeMax = 0.000;
				__localNetStream.backBufferTime = 0.000;
				__localNetStream.maxPauseBufferTime = 0.000;
				
				// h264 causes server-side warnings, possibly due to keyframe intervals, or the subscriber using .receiveFPS:
				// "TSorensonVideoSmartQueue would have dropped H264 sequence header/ender"
				//debugMsg('setupNetStream->  <selectedVideoCodec:'+AppWide_Singleton.getAppInfoObj().selectedVideoCodec+'>');
				if (AppWide_Singleton.getAppInfoObj().selectedVideoCodec.toLowerCase() == 'h264')
					__h264Settings = new H264VideoStreamSettings();
				else
					__h264Settings = null;
				
				if (__h264Settings)
					__localNetStream.videoStreamSettings = __h264Settings;
			} else {
				// close and nullify the current NetStream
				cleanupNetStream();
				
				// now recreate a new NetStream
				setupNetStream();
			}
		}
		
		
		// replaces part of setupNetStream
		private function cleanupNetStream(alreadyStoppedPublishing:Boolean=false):void
		{
			debugMsg("cleanupNetStream->  alreadyStoppedPublishing: "+alreadyStoppedPublishing+"  localNetStream: "+(__localNetStream?__localNetStream:""));
			
			if (!__localNetStream) return;
			
			__localNetStream.attachCamera(null);
			__localNetStream.attachAudio(null);
			
			// simple cleanup of any currently publishing NetStream
			if (!alreadyStoppedPublishing)
			{
				if ((__nc)&&(__nc.connected))
				{
					// TEST
					// normally not called by Flash Player,
					// dispatch application.onUnpublish on the server
					__nc.call("FCUnpublish", null, "user_"+this.userID); // throws an error if the NetConnection is not connected
					
					// clear MetaData
					__localNetStream.send("@clearDataFrame", "onMetaData"); // throws an error if the NetConnection is not connected
					
					__localNetStream.publish(null); // throws an error if the NetConnection is not connected
				}
				
				__localNetStream.close(); // does not dispatch application.onUnpublish
			} // end if not alreadyStoppedPublishing
			
			__localNetStream.dispose(); // does not dispatch application.onUnpublish
			
			// remove event listeners
			if ((__localNetStream) && (__localNetStream.hasEventListener(NetStatusEvent.NET_STATUS))) { __localNetStream.removeEventListener(NetStatusEvent.NET_STATUS, localNetStreamStatusEventHandler); }
			if ((__localNetStream) && (__localNetStream.hasEventListener(IOErrorEvent.NETWORK_ERROR))) { __localNetStream.removeEventListener(IOErrorEvent.NETWORK_ERROR, localNetStreamIOErrorHandler); }
			if ((__localNetStream) && (__localNetStream.hasEventListener(AsyncErrorEvent.ASYNC_ERROR))) { __localNetStream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, localNetStreamAsyncErrorHandler); }
			if ((__localNetStream) && (__localNetStream.hasEventListener(SecurityErrorEvent.SECURITY_ERROR))) { __localNetStream.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, localNetStreamSecurityError); }
			
			__localNetStream = null;
			__h264Settings = null;
			
			if (__localNetStream)
				debugMsg("cleanupNetStream->\t<WARNING>\tlocalNetStream:  "+__localNetStream+"  STILL EXISTS AFTER REMOVAL!");
		}
		
		
		
		// TODO
		// rename and separate with isPublishing
		// and isMyVideoOrAudioOn
		public function isPublishing():Boolean
		{
			if (isMyVideoOn || isMyAudioOn)
			{
				return true;
			} else {
				return false;
			}
		}
		
		
		public function isMyVideoOrAudioOn():Boolean
		{
			if (isMyVideoOn || isMyAudioOn)
			{
				return true;
			} else {
				return false;
			}
		}
		
		
		// start your video
		public function startVideo(_userID:Number):void
		{
			// if it is you sarting the video
			if (_userID == userID)
			{
				// TODO: use getLocalCamera/Mic
				//camera = (AppWide_Singleton.getInstance().localCamera ? AppWide_Singleton.getInstance().localCamera : Camera.getCamera())/*AppWide_Singleton.getLocalCamera()*/;
				//camera = AppWide_Singleton.getLocalCamera();
				//camera = AppWide_Singleton.getInstance().appInfoObj.selectedCameraName.length ? Camera.getCamera(Camera.names.indexOf(AppWide_Singleton.getInstance().appInfoObj.selectedCameraName) as String) : Camera.getCamera(Camera.names.indexOf("OBS Virtual Camera") as String);
				camera = AppWide_Singleton.getInstance().localCamera = Camera.getCamera(Camera.names.indexOf("OBS Virtual Camera") as String); //TEST

				debugMsg("startVideo->  camera: "+camera.name+"  localCamera: "+AppWide_Singleton.getInstance().localCamera.name+"  selectedCameraName: "+AppWide_Singleton.getInstance().appInfoObj.selectedCameraName);
				
				if (camera)
				{
					var defaultQuality:String = AppWide_Singleton.getAppInfoObj().defaultQuality;
					var camInputSizeStr_Arr:Array = LocalSOManager_Singleton.getInstance().getLocalSOProperty('selectedCameraInputSize').toString().split('x');
					var camWidth:int = camInputSizeStr_Arr[0];
					var camHeight:int = camInputSizeStr_Arr[1];
					
					debugMsg("startVideo->  STARTING YOUR VIDEO  defaultQuality: "+defaultQuality+"  camWidth: "+camWidth+"  camHeight: "+camHeight);
					
					if (!__localNetStream) setupNetStream();
					
					switch (defaultQuality)
					{
						case "low" :
							camera.setMode(camWidth,camHeight,1,false);
							//camera.setQuality(16384,90);
							camera.setQuality(16384,80);
							camera.setKeyFrameInterval(2);
							//camera.setKeyFrameInterval(2);
							if (__h264Settings)
							{
								//__h264Settings.setMode(camWidth,camHeight,1);
								//__h264Settings.setQuality(16384,80);
								//__h264Settings.setKeyFrameInterval(10);
								__h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_1_1);
							}
							break;
						case "medium" :
							camera.setMode(camWidth,camHeight,3,false);
							//camera.setQuality(40960,90);
							camera.setQuality(32768,80);
							camera.setKeyFrameInterval(6);
							//camera.setKeyFrameInterval(2);
							if (__h264Settings)
							{
								//__h264Settings.setMode(camWidth,camHeight,3);
								//__h264Settings.setQuality(32768,80);
								//__h264Settings.setKeyFrameInterval(30);
								__h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_1_1);
							}
							break;
						case "high" :
							camera.setMode(camWidth,camHeight,6,false);
							//camera.setQuality(65536,90);
							camera.setQuality(40960,80);
							camera.setKeyFrameInterval(12);
							//camera.setKeyFrameInterval(2);
							if (__h264Settings)
							{
								//__h264Settings.setMode(camWidth,camHeight,6);
								//__h264Settings.setQuality(40960,80);
								//__h264Settings.setKeyFrameInterval(48);
								__h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_1_2);
							}
							break;
						case "hd" :
							camera.setMode(camWidth,camHeight,8,false);
							//camera.setQuality(65536,90);
							camera.setQuality(65536,90);
							camera.setKeyFrameInterval(16);
							//camera.setKeyFrameInterval(2);
							if (__h264Settings)
							{
								//__h264Settings.setMode(camWidth,camHeight,8);
								//__h264Settings.setQuality(65536,90);
								//__h264Settings.setKeyFrameInterval(48);
								__h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_1_2);
							}
							break;
					}
					
					// apply the h264Settings
					if (__h264Settings)
						__localNetStream.videoStreamSettings = __h264Settings;
					
					__localNetStream.attachCamera(camera);
					
					if (!isPublishing())
					{
						startPublishing();
					}
					
					isMyVideoOn = true;
					
					// send the MetaData for this local clients video/audio
					sendMetaData();
					
					__nc.call("mediaManager.userVideoOn", null, clientID);
					
					camInputSizeStr_Arr = null;
					defaultQuality = null;
				} else {
					Alert.show("You don't seem to have a camera.");
				}
			}
		}
		
		
		// stop your video
		public function stopVideo(userID:Number):void
		{
			// if it is you stopping the video
			if (userID == this.userID)
			{
				debugMsg("stopVideo->  STOPPING YOUR VIDEO");
				
				if (isMyVideoOn)
				{
					__nc.call("mediaManager.userVideoOff", null, clientID);
					
					__localNetStream.attachCamera(null);
					
					isMyVideoOn = false;
					
					// AppWide_Singleton.getInstance().localCamera is still defined!
					camera = null;
					AppWide_Singleton.getInstance().localCamera = null;
					
					AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new Event('mediaManager_allStoppedViewing'));
				}
			}
			
			// stop publishing and close the NetStream if both video and audio are stopped,
			// or else nullify camera Objects now instead of during stopPublishing
			if (!isMyVideoOrAudioOn())
			{
				stopPublishing();
			}
		}
		
		
		// start your audio
		public function startAudio(userID:Number):void
		{
			// if it is you sarting the audio
			if (userID == this.userID)
			{
				var defaultQuality:String = AppWide_Singleton.getAppInfoObj().defaultQuality;
				var isUseSpeexCodecSelected:Boolean = AppWide_Singleton.getAppInfoObj().selectedAudioCodec.toLowerCase() == 'speex';
				
				debugMsg("startAudio->  STARTING YOUR AUDIO  defaultQuality: "+defaultQuality+"  isUseSpeexCodecSelected: "+isUseSpeexCodecSelected);
				
				// TODO: make AEC a user defined option.
				
				// force speex w/ Aucoustic Echo Cancellation
				if (isUseSpeexCodecSelected)
				{
					// TODO: use getLocalCamera/Mic
					mic = (AppWide_Singleton.getInstance().localMic ? AppWide_Singleton.getInstance().localMic : getEnhancedMic());
					
					//mic.setUseEchoSuppression(false);
				} else {
					// mic settings
					// TODO: use getLocalCamera/Mic
					mic = (AppWide_Singleton.getInstance().localMic ? AppWide_Singleton.getInstance().localMic : Microphone.getMicrophone());
					mic.codec = SoundCodec.NELLYMOSER;
					mic.gain = 50;
					
					// (if using speex, always) disable silence notifications
					// (no audio sent if mic has no activity for 2s).
					mic.setSilenceLevel(0, 2000);
					
					//mic.setUseEchoSuppression(false);
					mic.setLoopBack(false); // dont play through the speakers
				}
				
				switch (defaultQuality)
				{
					case "low" :
						mic.rate = isUseSpeexCodecSelected ? 8 : 11;
						break;
					case "medium" :
						mic.rate = isUseSpeexCodecSelected ? 8 : 22;
						break;
					case "high" :
						mic.rate = isUseSpeexCodecSelected ? 16 : 44;
						break;
					case "hd" :
						mic.rate = isUseSpeexCodecSelected ? 16 : 44;
						break;
				}
				
				if (!__localNetStream) setupNetStream();
				
				__localNetStream.attachAudio(mic);
				
				if (!isPublishing())
				{
					startPublishing();
				}
				
				isMyAudioOn = true;
				
				// send the MetaData for this local clients video/audio
				sendMetaData();
				
				__nc.call("mediaManager.userAudioOn", null, clientID);
				
				// TODO:
				// use the mic volume meter,
				// listen for mic activity via SampleDataEvent
				if (mic)
				{
					// start listening for mic activity
					//if ((mic)&&
					//	(!mic.hasEventListener(SampleDataEvent.SAMPLE_DATA)))
					//{
					//	mic.addEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
					//}
					
					// start listening for mic activity
					if (!micVolumeActivityTimer)
					{
						micVolumeActivityTimer = new Timer(125);
						micVolumeActivityTimer.addEventListener(TimerEvent.TIMER, onVolumeMeterUpdateHandler, false,0,true);
						
						//if (!micVolumeActivityTimer.running) 
						micVolumeActivityTimer.start();
					}
				}
				
				AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent('onLocalUserPublishAudio', false,false, {isPublishingAudio:true}));
			}
		}
		
		
		// stop your video
		public function stopAudio(userID:Number):void
		{
			// if it is you stopping the audio
			if (userID == this.userID)
			{
				debugMsg("stopAudio->  STOPPING YOUR AUDIO");
				
				if (isMyAudioOn)
				{
					// remove and cleanup the users vumeter
					// TODO
					
					// stop listening for mic activity
					if ((micVolumeActivityTimer)&&
						(micVolumeActivityTimer.hasEventListener(TimerEvent.TIMER)))
					{
						if (micVolumeActivityTimer.running) 
							micVolumeActivityTimer.stop();
						
						micVolumeActivityTimer.removeEventListener(TimerEvent.TIMER, onVolumeMeterUpdateHandler);
						micVolumeActivityTimer = null;
					}
					
					// stop listening for mic activity
					if ((mic)&&
						(mic.hasEventListener(SampleDataEvent.SAMPLE_DATA)))
					{
						mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
					}
					
					__nc.call("mediaManager.userAudioOff", null, clientID);
					
					__localNetStream.attachAudio(null);
					
					isMyAudioOn = false;
					
					mic = null;
					AppWide_Singleton.getInstance().localMic = null;
					
					AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new Event('mediaManager_allStoppedListening'));
				}
				
				// stop publishing and close the NetStream if both video and audio are stopped,
				// or else nullify mic Objects now instead of during stopPublishing
				if (!isMyVideoOrAudioOn())
				{
					stopPublishing();
				}
			}
		}
		
		
		// Acoustic Echo Cancellation
		// TODO:
		// make MicrophoneEnhancedOptions a class variable,
		// and handle AEC for both NELLYMOSER and SPEEX
		private function getEnhancedMic():Microphone
		{
			var isUseSpeexCodecSelected:Boolean = AppWide_Singleton.getAppInfoObj().selectedAudioCodec.toLowerCase() == 'speex';
			
			// TODO: use getLocalCamera/Mic
			var microphone:Microphone = Microphone.getEnhancedMicrophone();
			
			if (microphone)
			{
				var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
				
				// enhanced options
				options.autoGain = false;
				options.nonLinearProcessing = false; // turn off for music
				options.echoPath = 128; // can be increased to 256 for less echo
				// use half duplex for usb headsets, full duplex for builtin mics
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
				
				microphone.enhancedOptions = options;
				
				options = null;
			} else {
				// else getEnhancedMicrophone returned null,
				// return a normal Microphone.
				
				// TODO: use getLocalCamera/Mic
				microphone = Microphone.getMicrophone();
			}
			
			// encoding settings
			// TODO: use user defined settings.
			// TODO: separate codec specific options.
			if (microphone)
			{
				microphone.setLoopBack(false); // listen to the output, causes feedback
				
				if (isUseSpeexCodecSelected)
					microphone.codec = SoundCodec.SPEEX;
				else
					microphone.codec = SoundCodec.NELLYMOSER;
				
				if (isUseSpeexCodecSelected) microphone.rate = 16; // 8 or 16
				
				microphone.gain = 50;
				microphone.setSilenceLevel(0, 2000);
				
				// help reduce speaker audio from being picked up by the microphone
				//microphone.setUseEchoSuppression(true); // method is ignored when using acoustic echo cancellation.
				
				// speex specific encoding settings
				if (isUseSpeexCodecSelected) microphone.encodeQuality = 8; // 1-10
				if (isUseSpeexCodecSelected) microphone.framesPerPacket = 1; // speex only
				if (isUseSpeexCodecSelected) microphone.noiseSuppressionLevel = 0; // speex only
				if (isUseSpeexCodecSelected) microphone.enableVAD = false; // voice activity detection, speex only
				
				//microphone.addEventListener(ActivityEvent.ACTIVITY, activityHandler, false,0,true);
				//microphone.addEventListener(StatusEvent.STATUS, statusHandler, false,0,true);
			}
			
			return microphone;
		}
		
		
		private function onVolumeMeterUpdateHandler(event:TimerEvent):void
		{
			//debugMsg("onVolumeMeterUpdateHandler->  localUserAudioInputVolumeMeter: "+localUserAudioInputVolumeMeter+"  mic.name: "+mic.name+"  activity: "+mic.activityLevel+"%");
			
			if (localUserAudioInputVolumeMeter != null)
			{
				localUserAudioInputVolumeMeter.parent["onVolumeMeterUpdateHandler"](event.clone());
			}
			
			event = null;
		}
		
		
		private function gotMicData(micData:SampleDataEvent):void
		{
			//debugMsg("gotMicData->  mic.name: "+mic.name+"  activity: "+mic.activityLevel+"%");
			
			if (localUserAudioInputVolumeMeter != null)
			{
				localUserAudioInputVolumeMeter.parent["gotMicData"](micData.clone());
				
				//var currentMicActivityLevel:int = (microphone.activityLevel+50) / 100;
				//var currentMicActivityLevel:uint = (microphone.activityLevel / 100);
				
				// resize/rescale volume meter mask using microphone.activityLevel
				//localUserAudioInputVolumeMeter.scaleY = microphone.activityLevel / 100;
				//localUserAudioInputVolumeMeter.mask.scaleY = mic.activityLevel / 100;
				
				// move to the end of the vumeter image
				// (show the meter starting from the beginning)
				//localUserAudioInputVolumeMeter.mask.y = localUserAudioInputVolumeMeter.height-(localUserAudioInputVolumeMeter.height*((mic.activityLevel)/100));
				
				//debugMsg("\t\t\t\t\t  localUserAudioInputVolumeMeter: "+localUserAudioInputVolumeMeter.x+","+localUserAudioInputVolumeMeter.y+","+localUserAudioInputVolumeMeter.width+","+localUserAudioInputVolumeMeter.height+"  localUserAudioInputVolumeMeter.mask: "+localUserAudioInputVolumeMeter.mask.x+","+localUserAudioInputVolumeMeter.mask.y+","+localUserAudioInputVolumeMeter.mask.width+","+localUserAudioInputVolumeMeter.mask.height);
			} else {
				//debugMsg("gotMicData->  ");
			}
			
			micData = null;
		}
		
		
		// TODO
		// separate relevant code to startVideo/Audio.
		// publish a NetStream to the server.
		public function startPublishing():void
		{
			/*var appInfoObj:Object = AppWide_Singleton.getAppInfoObj();
			var camInputSizeStr_Arr:Array = appInfoObj.selectedCameraInputSize.toString().split('x');
			var camWidth:int = camInputSizeStr_Arr[0];
			var camHeight:int = camInputSizeStr_Arr[1];
			var isUseSpeexCodecSelected:Boolean = appInfoObj.selectedAudioCodec.toLowerCase() == 'speex';*/
			
			//if (!__localNetStream) setupNetStream();
			
			debugMsg("startPublishing->  userID: "+this.userID+"  defaultQuality: "+AppWide_Singleton.getAppInfoObj().defaultQuality+"  localNetStream: "+__localNetStream+"  isMyVideoOn: "+isMyVideoOn+"  isMyAudioOn: "+isMyAudioOn/*+"  camWidth: "+camWidth+"  camHeight: "+camHeight*/);
			
			// TODO:
			// default to Speex when using rtmfp
			
			// TEST
			// normally not called by Flash Player.
			// TODO: wait for the servers approval
			__nc.call("FCPublish", null, "user_"+this.userID);
			
			// publish the live stream
			__localNetStream.publish("user_" + this.userID, "live");
			
			// set the LIVE buffer (no buffering),
			// not working?!
			__localNetStream.useJitterBuffer = true;
			__localNetStream.bufferTime = 0.000;
			__localNetStream.bufferTimeMax = 0.000;
			__localNetStream.backBufferTime = 0.000;
			__localNetStream.maxPauseBufferTime = 0.000;
		}
		
		
		public function stopPublishing():void
		{
			debugMsg("stopPublishing->  userID: "+this.userID+"  localNetStream: "+__localNetStream+"  isMyVideoOn: "+isMyVideoOn+"  isMyAudioOn: "+isMyAudioOn);
			
			// stop listening for mic activity
			if ((micVolumeActivityTimer)&&
				(micVolumeActivityTimer.hasEventListener(TimerEvent.TIMER)))
			{
				if (micVolumeActivityTimer.running) 
					micVolumeActivityTimer.stop();
				
				micVolumeActivityTimer.removeEventListener(TimerEvent.TIMER, onVolumeMeterUpdateHandler);
				micVolumeActivityTimer = null;
			}
			
			// stop listening for volume meter mic activity
			if ((mic)&&
				(mic.hasEventListener(SampleDataEvent.SAMPLE_DATA)))
			{
				mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
			}
			
			//if ((__nc)&&(__nc.connected)&&(__localNetStream))
			if (__localNetStream)
			{
				// unpublish the NetStream from the server
				if ((__nc)&&(__nc.connected))
				{
					// TEST
					// normally not called by Flash Player,
					// dispatch application.onUnpublish on the server
					__nc.call("FCUnpublish", null, "user_"+this.userID); // throws an error if the NetConnection is not connected
					
					// clear MetaData
					__localNetStream.send("@clearDataFrame", "onMetaData"); // throws an error if the NetConnection is not connected
					
					__localNetStream.publish(null); // throws an error if the NetConnection is not connected
					
					//__localNetStream.close(); // does not dispatch application.onUnpublish
					__localNetStream.dispose(); // does not dispatch application.onUnpublish
				}
				
				// detatch cam/mic whether or not the NetConnection is connected, AFTER NetStream.close/dispose
				__localNetStream.attachCamera(null);
				__localNetStream.attachAudio(null);
				
				// reset the NetStream for reuse.
				// pass true since we already stopped publishing
				cleanupNetStream(true);
			}
			
			camera = null;
			mic = null;
			AppWide_Singleton.getInstance().localCamera = null;
			AppWide_Singleton.getInstance().localMic = null;
		}
		
		
		// TODO
		public function close():void
		{
			stopPublishing();
			
			// empty the viewed/heardByUserIDs_A arrays 
			viewedByUserIDs_A.splice(0);
			heardByUserIDs_A.splice(0);
			
			// stop listening for volume meter mic activity
			if ((micVolumeActivityTimer)&&
				(micVolumeActivityTimer.hasEventListener(TimerEvent.TIMER)))
			{
				if (micVolumeActivityTimer.running) 
					micVolumeActivityTimer.stop();
				
				micVolumeActivityTimer.removeEventListener(TimerEvent.TIMER, onVolumeMeterUpdateHandler);
				micVolumeActivityTimer = null;
			}
			
			// stop listening for volume meter mic activity
			if ((mic)&&
				(mic.hasEventListener(SampleDataEvent.SAMPLE_DATA)))
			{
				mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, gotMicData);
			}
			
			// reset isMy*On
			isMyVideoOn = false;
			isMyAudioOn = false;
			
			myMetaData = null;
			
			camera = null;
			mic = null;
			AppWide_Singleton.getInstance().localCamera = null;
			AppWide_Singleton.getInstance().localMic = null;
			
			if (__mediaSO)
			{
				__mediaSO.close();
				__mediaSO.clear();
				__mediaSO = null;
			}
			
			clientID = '';
			acctID = 0;
			acctName = '';
			userID = 0;
			userName = '';
		}
		
		
		
		
		
		
		
		
		
		
		
		
		/*************** NetStream event/.client handlers ******************/
		
		private function localNetStreamStatusEventHandler(event:NetStatusEvent):void
		{
			debugMsg("localNetStreamStatusEventHandler->  code: "+event.info.code);
			var code:String = event.info.code;
			
			switch (code)
			{
				case "NetStream.Publish.Start" :
					// publishing has started
					break;
				case "NetStream.Publish.Stop" :
					// publishing has stopped
					break;
				case "NetStream.Play.StreamNotFound" :
					// usually means bad streamName.. create an error alert for the user
					break;
				case "NetStream.Play.Complete" :
					// VOD video has ended
					break;
				case "NetStream.Play.PublishNotify" :
					break;
				case "NetStream.Play.UnpublishNotify" :
					break;
				case "NetStream.Video.DimensionChange" :
					//debugMsg("localNetStreamStatusEventHandler->  ");
					break;
				case "NetStream.Seek.Notify" :
					break;
				case "NetStream.Play.InsufficientBW" :
					debugMsg("localNetStreamStatusEventHandler->  <InsufficientBW>"+
						"\n\tbuffer: "+(Math.floor(__localNetStream.bufferTime / __localNetStream.bufferLength) * 100)+
						//"\n\tbuffer: "+((__localNetStream.bufferTime / __localNetStream.bufferLength) * 100)+
						"\n\tbufferLength: "+__localNetStream.bufferLength+
						"\n\tbufferTime: "+__localNetStream.bufferTime+
						"\n\tbufferTimeMax: "+__localNetStream.bufferTimeMax+
						"\n\tmaxPauseBufferTime: "+__localNetStream.maxPauseBufferTime+
						"\n\tbackBufferLength: "+__localNetStream.backBufferLength+
						"\n\tbackBufferTime: "+__localNetStream.backBufferTime+
						"\n\tuseJitterBuffer: "+__localNetStream.useJitterBuffer+
						"\n\tinBufferSeek: "+__localNetStream.inBufferSeek+
						"\n\tliveDelay: "+__localNetStream.liveDelay+
						//"\n\n\tNetStreamInfo: "+__localNetStream.info.toString()+
						"\n\n");
					break;
				default :
					debugMsg("localNetStreamStatusEventHandler->  UNHANDLED CASE: "+event.info.code);
					break;
			}
			
			event.stopPropagation();
			
			event = null;
		}
		
		
		private function localNetStreamAsyncErrorHandler(event:AsyncErrorEvent):void
		{ 
			debugMsg("localNetStreamAsyncErrorHandler->  errorID: "+event.errorID+"  error: "+event.error+"  text: "+event.text);
			
			event.stopPropagation();
			
			event = null;
		}
		
		
		private function localNetStreamIOErrorHandler(event:IOErrorEvent):void
		{ 
			debugMsg("localNetStreamIOErrorHandler->  errorID: "+event.errorID/*+"  error: "+event.error*/+"  text: "+event.text);
			
			event.stopPropagation();
			
			event = null;
		}
		
		
		private function localNetStreamSecurityError(event:SecurityErrorEvent):void
		{
			debugMsg("localNetStreamSecurityError->  errorID: "+event.errorID/*+"  error: "+event.error*/+"  text: "+event.text);
			
			event.stopPropagation();
			
			event = null;
		}
		
		
		
		
		private function sendMetaData():void
		{ 
			//debugMsg("sendMetaData() called");
			
			//var myMetaData:Object = {};
			
			// TODO:
			// only send static info that does not
			// change after being sent
			myMetaData.userID = userID;
			myMetaData.userName = userName;
			myMetaData.acctID = acctID;
			myMetaData.acctName = acctName;
			myMetaData.defaultQuality = AppWide_Singleton.getAppInfoObj().defaultQuality;
			
			myMetaData.inBufferSeek = __localNetStream.inBufferSeek;
			myMetaData.useJitterBuffer = __localNetStream.useJitterBuffer;
			myMetaData.backBufferTime = __localNetStream.backBufferTime;
			myMetaData.bufferTimeMax = __localNetStream.bufferTimeMax;
			myMetaData.bufferTime = __localNetStream.bufferTime;
			myMetaData.liveDelay = __localNetStream.liveDelay;
			myMetaData.isLive = __localNetStream.info.isLive;
			
			if (camera)
			{
				myMetaData.camera = camera.name;
				myMetaData.width = camera.width;
				myMetaData.height = camera.height;
				
				myMetaData.camQuality = camera.quality;
				myMetaData.bandwidth = camera.bandwidth;
				myMetaData.keyFrameInterval = camera.keyFrameInterval;
				myMetaData.currentFPS = camera.currentFPS;
				myMetaData.maxFPS = camera.fps;
				
				myMetaData.videoCodec = __localNetStream.videoStreamSettings ? __localNetStream.videoStreamSettings.codec : "TODO";
				myMetaData.videoCodecID = __localNetStream.videoCodec;
				
				if (__h264Settings)
				{
					myMetaData.profile = __h264Settings.profile;
					myMetaData.level = __h264Settings.level;
				}
			}
			
			if (mic)
			{
				myMetaData.microphone = mic.name; // AEC later
				myMetaData.audioRate = mic.rate;
				myMetaData.audioCodec = mic.codec;
				myMetaData.audioCodecID = __localNetStream.audioCodec; // use speex with AEC, later
				myMetaData.audioActivityLevel = mic.activityLevel;
			}
			
			myMetaData.currentConnectionProtocol = __nc.protocol;
			
			// add current RTMFP metadata
			if (myMetaData.currentConnectionProtocol == "rtmfp")
			{
				myMetaData.dataReliable = __localNetStream.dataReliable;
				myMetaData.videoReliable = __localNetStream.videoReliable;
				myMetaData.audioReliable = __localNetStream.audioReliable;
				myMetaData.multicastAvailabilitySendToAll = __localNetStream.multicastAvailabilitySendToAll;
				myMetaData.multicastAvailabilityUpdatePeriod = __localNetStream.multicastAvailabilityUpdatePeriod;
				myMetaData.multicastFetchPeriod = __localNetStream.multicastFetchPeriod;
				myMetaData.multicastPushNeighborLimit = __localNetStream.multicastPushNeighborLimit;
				myMetaData.multicastRelayMarginDuration = __localNetStream.multicastRelayMarginDuration;
				myMetaData.multicastWindowDuration = __localNetStream.multicastWindowDuration;
				
				if (__localNetStream.client.onPeerConnect)
					myMetaData.onPeerConnect = __localNetStream.client.onPeerConnect.toString();
			}
			
			__localNetStream.send("@setDataFrame", "onMetaData", myMetaData);
			
			// debug
			for (var i:* in myMetaData)
				debugMsg("sendMetaData->\t"+i+" = "+myMetaData[i]);
			/*
			for (var x:* in __localNetStream)
			debugMsg("sendMetaData->\t<NetStream>\t\t"+x+": "+__localNetStream[x]);
			
			for (var y:* in __localNetStream.videoStreamSettings)
			debugMsg("sendMetaData->\t<NetStream.videoStreamSettings>\t\t"+y+": "+__localNetStream.videoStreamSettings[y]);
			
			for (var z:* in __localNetStream.info)
			debugMsg("sendMetaData->\t<NetStream.info>\t\t"+z+": "+__localNetStream.info[z]);
			
			if (__localNetStream.multicastInfo)
			{
			for (z in __localNetStream.multicastInfo)
			debugMsg("sendMetaData->\t<NetStream.multicastInfo>\t\t"+z+": "+__localNetStream.multicastInfo[z]);
			}
			
			z = null;
			y = null;
			x = null;*/
			i = null;
			//myMetaData = null;
		}
		
		
		
		// RTMFP only (p2p, not used)
		public function onPeerConnect(subscriber:NetStream):Boolean
		{
			debugMsg("onPeerConnect->  subscriber: "+subscriber);
			
			subscriber = null;
			
			return isMediaPrivate;
		}
		
		
		/*
		// RTMFP only (p2p, not used)
		public function onFCSubscribe(infoObj:Object):void
		{
		debugMsg("onFCSubscribe->  infoObj: "+infoObj);
		
		infoObj = null;
		}
		*/
		
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			AppWideDebug_Singleton.getInstance().newDebugMessage('MediaManager', str);
			
			str = null;
		}
		
		
	}// end class
}// end package