/*
	whohacked.me - rjp421@gmail.com
*/
package me.whohacked.app
{
	
	import flash.events.ErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	
	import events.CustomEvent;
	
	
	
	
	public class LocalSOManager_Singleton
	{
		
		public var isLocalSOAllowed:Boolean; // is flash allowed to store local SharedObjects
		public var localSO:SharedObject; // the Local Shared Object used in this application
		
		private var __initialized:Boolean; // has this singleton has been instantiated
		private static var __instance:LocalSOManager_Singleton; // reference to the instance of this singleton
		
		
		
		public function LocalSOManager_Singleton()
		{
			if (__instance)
				throw new Error("LocalSOManager_Singleton is a singleton class, use .getInstance() instead!");
			
			init(); // instantiate the initial components
		}
		
		
		private function init():void // instantiate the static variables
		{
			if (!__initialized) // if this Singleton has not been instantiated yet
			{
				__initialized = true; // the class has now been instantiated
			}
			
			// check and initialize the locally saved settings
			initLocalSOManager();
		}
		
		
		public static function getInstance():LocalSOManager_Singleton
		{
			if (__instance==null)
			{
				__instance = new LocalSOManager_Singleton();
			}
			
			return __instance;
		}
		
		
		public function initLocalSOManager():void
		{
			if (!localSO)
			{
				try	{
					localSO = SharedObject.getLocal('HotTub', '/beta/HotTub.swf'); // CHANGE
					
					// clear SO - debug only
					//localSO.clear();
					
					if (!localSO.hasEventListener(ErrorEvent.ERROR))
						localSO.addEventListener(ErrorEvent.ERROR, onSOError, false,0,true);
					
					if (!localSO.hasEventListener(NetStatusEvent.NET_STATUS))
						localSO.addEventListener(NetStatusEvent.NET_STATUS, onLocalSOStatus, false,0,true);
					
					if (!localSO.hasEventListener(SharedObjectFlushStatus.PENDING))
						localSO.addEventListener(SharedObjectFlushStatus.PENDING, onSOFlushPending, false,0,true);
					
					if (!localSO.hasEventListener(SharedObjectFlushStatus.FLUSHED))
						localSO.addEventListener(SharedObjectFlushStatus.FLUSHED, onSOFlushed, false,0,true);
					
					if ((flush()) && (localSO.size == 0))
					{
						setupDefaultSettings();
					}
					
					// for debug
					/*
					for (var i:Object in localSO.data)
					{
						debugMsg('localSO->  '+i + ':\t' + localSO.data[i]);
					}
					*/
					
					debugMsg('initLocalSOManager->  localSO: '+localSO+'  currentSize: '+localSO.size+'  isLocalSOAllowed: '+isLocalSOAllowed);
				} catch (error:*) {
					debugMsg('initLocalSOManager->  localSO: '+localSO+'  error: '+error);
					
					isLocalSOAllowed = false;
					
					reset();
					
					error = null;
				}
			}
		}
		
		
		public function flush():Boolean
		{
			if (!localSO) return false;
			
			// if flush() returns 'flushed', or SharedObjectFlushStatus.FLUSHED
			var str:String = localSO.flush();
			
			debugMsg('flush->  str: '+str);
			
			if (str == 'flushed')
			{
				isLocalSOAllowed = true;
			}
			else if (str == 'pending')
			{
				isLocalSOAllowed = false;
			}
			
			return isLocalSOAllowed;
		}
		
		
		private function onLocalSOStatus(event:NetStatusEvent):void
		{
			if (!localSO) return;
			
			debugMsg('onLocalSOStatus->  status: '+event.info.code);
			
			var code:String = event.info.code;
			
			switch (code)
			{
				case 'SharedObject.Flush.Failed' :
					isLocalSOAllowed = false;
					break;
				case 'SharedObject.Flush.Success' :
					isLocalSOAllowed = true;
					break;
			}
			
			var tmpObj:Object = {status:code, isLocalSOAllowed:this.isLocalSOAllowed, size:localSO.size};
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent('onLocalSOStatus',false,false, tmpObj));
			
			tmpObj = null;
			code = null;
			event = null;
		}
		
		
		// flush completed successfully
		private function onSOFlushed(event:SharedObjectFlushStatus):void
		{
			debugMsg('LOCAL SO FLUSH SUCCESSFUL->  ');
			event = null;
		}
		
		
		// flash is not allowed to write to disk
		private function onSOFlushPending(event:SharedObjectFlushStatus):void
		{
			debugMsg('LOCAL SO FLUSH PENDING->  ');
			event = null;
		}
		
		
		private function onSOError(event:ErrorEvent):void
		{
			debugMsg('LOCAL SO ERROR->  error: '+event.type);
			event = null;
		}
		
		
		private function setupDefaultSettings():void
		{
			debugMsg('setupDefaultSettings->  current size: '+localSO.size);
			
			setLocalSOProperty('login','');
			setLocalSOProperty('pass','');
			setLocalSOProperty('lastRoomName','lobby');
			setLocalSOProperty('version','0');
			setLocalSOProperty('debugMode',false);
			
			setLocalSOProperty('isBanned',false);
			setLocalSOProperty('isLayoutUnlocked',false);
			setLocalSOProperty('isSavePasswordChecked',false);
			setLocalSOProperty('isAutoFillCamsChecked',true);
			setLocalSOProperty('isAllFontSizeChecked',false);
			setLocalSOProperty('isAllCamsOffChecked',false);
			setLocalSOProperty('isAllAudioOffChecked',true);
			setLocalSOProperty('isUseOthersQualityChecked',false);
			setLocalSOProperty('isVoiceChatEnabled',false);
			
			setLocalSOProperty('isAutoReconnectEnabled',true);
			setLocalSOProperty('isAutoAdjustForBWEnabled',true);
			
			setLocalSOProperty('isRoomHostOnMainChecked',true);
			setLocalSOProperty('isUnmuteRoomHostChecked',true);
			setLocalSOProperty('isShowTimestampsChecked',true);
			
			setLocalSOProperty('selectedConnectionProtocol','rtmp');
			setLocalSOProperty('selectedLayout','medium');
			setLocalSOProperty('selectedCameraName','');
			setLocalSOProperty('selectedCameraInputSize','160x120');
			setLocalSOProperty('selectedMicrophoneName','Default');
			setLocalSOProperty('selectedVideoCodec','sorenson');
			setLocalSOProperty('selectedAudioCodec','nellymoser');
			
			setLocalSOProperty('showBWChart',true);
			setLocalSOProperty('showCamSpotStats',false);
			
			// move autoStartCams to the per-room settings
			setLocalSOProperty('autoStartCams',true); // dock user cams to all empty camspots after joining a room
			setLocalSOProperty('autoPauseCams',false); // video paused after being docked
			setLocalSOProperty('autoMuteCams',true); // audio muted be default after being docked
			setLocalSOProperty('autoJoinRoomOnLogin',true); // auto-join the room after logging in
			setLocalSOProperty('autoPrivateMedia',false); // automatically make the users video/audio private
			setLocalSOProperty('autoUseOthersQuality',false); // automatically use other users selected quality when viewing their media
			
			setLocalSOProperty('fontSize',14);
			setLocalSOProperty('fontColor',000000);
			setLocalSOProperty('fontFace','Verdana');
			setLocalSOProperty('fontBold',false);
			setLocalSOProperty('fontItalics',false);
			setLocalSOProperty('fontUnderline',false);
			
			setLocalSOProperty('defaultQuality','hd');
			setLocalSOProperty('defaultBGColor',0x333333);
			setLocalSOProperty('defaultAppBGColor',0x333333);
			setLocalSOProperty('defaultAppTextFont','Verdana');
			
			clearIgnores();
			
			// NEW TEST
			/*
			setLocalSOProperty(,);
			setLocalSOProperty(,);
			setLocalSOProperty(,);
			setLocalSOProperty(,);
			setLocalSOProperty(,);
			setLocalSOProperty(,);
			setLocalSOProperty(,);
			*/
			
			/*
			// old code, temporarily kept for reference
			var ignores:Object = new Object();
			var names:Object = new Object();
			var acctids:Object = new Object();
			ignores.names = names;
			ignores.acctids = acctids;
			setLocalSOProperty('ignores',ignores);
			*/
		}
		
		
		public function setLocalSOProperty(property:String, value:*):void
		{
			if (!localSO) return;
			
			debugMsg('setLocalSOProperty->  current size: '+localSO.size+'  |  '+property+' = '+(((property=="pass") && (value.toString().length)) ? '' : value));
			
			localSO.data[property] = value;
			
			if (isLocalSOAllowed) localSO.flush();
			
			property = null;
		}
		
		
		public function getLocalSOProperty(property:String):*
		{
			if (!localSO || !isLocalSOAllowed)
			{
				var _appInfoObj:Object = AppWide_Singleton.getAppInfoObj();
				
				//debugMsg("getLocalSOProperty->  property: " + property + "  value: " + _appInfoObj[property]);
				
				return _appInfoObj[property];
			}
			
			//debugMsg('getLocalSOProperty->  current size: '+__localSO.size+'  property: '+property);
			
			var returnObj:*;
			
			if (localSO.size != 0)
			{
				returnObj = localSO.data[property];
			} else {
				returnObj = new Object();
			}
			
			property = null;
			
			return returnObj;
		}
		
		
		
		public function clearIgnores():void
		{
			if (!localSO) return;
			
			if (localSO.data.ignores)
			{
				localSO.data.ignores = null;
			}
			
			//localSO.data.ignores = {names:{}, acctids:{}};
			localSO.data.ignores = {};
			
			if (isLocalSOAllowed) localSO.flush();
		}
		
		
		
		public function resetToDefaults():void
		{
			if (!localSO) return;
			
			// clear the SO
			localSO.clear();
			
			// redefine the default settings
			setupDefaultSettings();
		}
		
		
		public function reset():void
		{
			if (localSO)
			{
				if (localSO.hasEventListener(ErrorEvent.ERROR))
					localSO.removeEventListener(ErrorEvent.ERROR, onSOError);
				
				if (localSO.hasEventListener(NetStatusEvent.NET_STATUS))
					localSO.removeEventListener(NetStatusEvent.NET_STATUS, onLocalSOStatus);
				
				if (localSO.hasEventListener(SharedObjectFlushStatus.PENDING))
					localSO.removeEventListener(SharedObjectFlushStatus.PENDING, onSOFlushPending);
				
				if (localSO.hasEventListener(SharedObjectFlushStatus.FLUSHED))
					localSO.removeEventListener(SharedObjectFlushStatus.FLUSHED, onSOFlushed);
				
				localSO.clear();
				localSO.close();
				
				localSO = null;
			} else {
				trace("### CREATING TEMP LocalSO ###");
				
				// create a temp SO
				localSO = SharedObject.getLocal("HotTub", "/");
				
				if (!localSO.hasEventListener(ErrorEvent.ERROR))
					localSO.addEventListener(ErrorEvent.ERROR, onSOError, false,0,true);
				
				if (!localSO.hasEventListener(NetStatusEvent.NET_STATUS))
					localSO.addEventListener(NetStatusEvent.NET_STATUS, onLocalSOStatus, false,0,true);
				
				if (!localSO.hasEventListener(SharedObjectFlushStatus.PENDING))
					localSO.addEventListener(SharedObjectFlushStatus.PENDING, onSOFlushPending, false,0,true);
				
				if (!localSO.hasEventListener(SharedObjectFlushStatus.FLUSHED))
					localSO.addEventListener(SharedObjectFlushStatus.FLUSHED, onSOFlushed, false,0,true);
				
				setupDefaultSettings();
			}
			
			initLocalSOManager();
		}
		
		
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			//AppWideDebug_Singleton.getInstance().newDebugMessage('LocalSOManager', str);
			
			trace('LocalSOManager | ' + str);
			
			str = null;
		}	
		
		
	} // end class
} // end package