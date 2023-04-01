/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
package scripts.net
{
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.utils.ObjectUtil;
	
	import events.CustomEvent;
	
	import me.whohacked.app.AppWideDebug_Singleton;
	import me.whohacked.app.AppWideEventDispatcher_Singleton;
	
	
	
		
	public class NetConnectionClient extends EventDispatcher
	{
		
		
		public function NetConnectionClient(target:IEventDispatcher=null)
		{
			debugMsg("->  LOADED");
			super(target);
			
			target = null;
		}
		
		
		public function loginFail(reason:String):void
		{
			debugMsg("loginFail->  LOGIN FAILED  reason: "+reason);
			var msgObj:Object = new Object();
			msgObj.reason = reason;
			
			dispatchEvent(new CustomEvent("loginFailed", false, false, msgObj));
			
			msgObj = null;
			reason = null;
		}
		
		
		// listen for setUserID from the server, then dispatch createLobby along with the userID
		public function setUserID(clientID:String, acctID:String, userID:String, userName:String, userListObj:Object, blockedUsersObj:Object):void
		{
			debugMsg("setUserID->  clientID: "+clientID+"  acctID: "+acctID+"  userID: "+userID+"  userName: "+userName+"  userListObj: "+userListObj);
			
			var tmpObj:Object = new Object();
			tmpObj.clientID = clientID;
			tmpObj.acctID = acctID;
			tmpObj.userID = userID;
			tmpObj.userName = userName;
			tmpObj.userListObj = userListObj;
			tmpObj.blockedUsersObj = blockedUsersObj;
			
			dispatchEvent(new CustomEvent("createLobby", false, false, tmpObj));
			
			tmpObj = null;
			blockedUsersObj = null;
			userListObj = null;
			userName = null;
			userID = null;
			acctID = null;
			clientID = null;
		}
		
		
		public function onBWCheck(... rest):Number
		{
			//debugMsg("onBWCheck->  CALLED");
			
			return 0;
		}
		
		
		public function onBWDone(... rest):void
		{
			var bwCheckResults_kbits:Number;
			var latency:Number;
			if (rest.length > 0)
			{
				bwCheckResults_kbits = rest[0];
				
				if (rest[3])
					latency = rest[3];
				else
					latency = 0;
			}
			
			var msg:String = "Bandwidth:  "+bwCheckResults_kbits+" Kb/s,  "+0.125*bwCheckResults_kbits+" KB/s,  "+bwCheckResults_kbits/1000+" Mb/s"/*,  "+bwCheckResults_kbits/8000+" MB/s"*/+(latency>0 ? ",  latency: "+latency : "");
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("onBWDone", false, false, {bitrate:bwCheckResults_kbits, latency:latency}));
			
			dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:msg}));
			
			debugMsg("onBWDone->  "+msg);
			
			msg = null;
		}
		
		
		public function onFCPublish(infoObj:Object):void
		{
			debugMsg("onFCPublish->  "+(infoObj.code?"  code: "+infoObj.code:"")+(infoObj.description?"  description: "+infoObj.description:""));
			
			var _infoObj:Object = infoObj;
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("onFCPublish", false, false, _infoObj));
			
			_infoObj = null;
			infoObj = null;
		}
		
		
		public function onFCUnpublish(infoObj:Object):void
		{
			debugMsg("onFCUnpublish->  "+(infoObj.code?"  code: "+infoObj.code:"")+(infoObj.description?"  description: "+infoObj.description:""));
			
			var _infoObj:Object = infoObj;
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("onFCUnpublish", false, false, _infoObj));
			
			_infoObj = null;
			infoObj = null;
		}
		
		
		public function receiveMessage(msgObj:Object):void
		{
			var _msgObj:Object = msgObj;
			
			dispatchEvent(new CustomEvent("receiveMessage", false, false, _msgObj));
			
			_msgObj = null;
			msgObj = null;
		}
		
		
		public function receivePrivateMessage(msgObj:Object):void
		{
			var _msgObj:Object = msgObj;
			
			dispatchEvent(new CustomEvent("receivePrivateMessage", false, false, _msgObj));
			
			_msgObj = null;
			msgObj = null;
		}
		
		
		public function receiveBannedUsers(resultObj:Object):void
		{
			//debugMsg("receiveBannedUsers->  resultObj: " + resultObj);
			
			var tmpObj:Object = resultObj;
			
			dispatchEvent(new CustomEvent("receiveBannedUsers", false, false, tmpObj));
			
			tmpObj = null;
			resultObj = null;
		}
		
		/*
		public function receiveBlockedUsers(resultObj:Object):void
		{
			var tmpObj:Object = resultObj;
			
			debugMsg("receiveBlockedUsers->  resultObj: "+tmpObj+"  =  "+ObjectUtil.toString(tmpObj));
			
			dispatchEvent(new CustomEvent("onGetBlockedUsersListResult", false, false, tmpObj));
			
			tmpObj = null;
			resultObj = null;
		}
		*/
		
		public function showAdminMessage(msgObj:Object):void
		{
			var tmpObj:Object = msgObj;
			
			//debugMsg("showAdminMessage->  msgObj: "+tmpObj+"  msg: "+tmpObj.msg);
			dispatchEvent(new CustomEvent("showAdminMessage", false, false, tmpObj));
			
			tmpObj = null;
			msgObj = null;
		}
		
		
		public function kicked(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("kicked", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function banned(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("banned", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		
		public function userList_addUser(tmpObj:Object):void
		{
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("userList_addUser", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userList_removeUser(tmpObj:Object):void
		{
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("userList_removeUser", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userList_onGetUserList(tmpObj:Object):void
		{
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("userList_onGetUserList", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userVideoOn(_userID:Number):void
		{
			//trace("|###| NetConnectionClient.userVideoOn |###|>  userID: " + _userID);
			
			dispatchEvent(new CustomEvent("mediaSOClient_userVideoOn", false,false, {userID:_userID}));
		}
		
		
		public function userVideoOff(_userID:Number):void
		{
			//trace("|###| NetConnectionClient.userVideoOff |###|>  userID: " + _userID);
			
			dispatchEvent(new CustomEvent("mediaSOClient_userVideoOff", false,false, {userID:_userID}));
		}
		
		
		public function userAudioOn(_userID:Number):void
		{
			//trace("|###| NetConnectionClient.userAudioOn |###|>  userID: " + _userID);
			
			dispatchEvent(new CustomEvent("mediaSOClient_userAudioOn", false,false, {userID:_userID}));
		}
		
		
		public function userAudioOff(_userID:Number):void
		{
			//trace("|###| NetConnectionClient.userAudioOff |###|>  userID: " + _userID);
			
			dispatchEvent(new CustomEvent("mediaSOClient_userAudioOff", false,false, {userID:_userID}));
		}
		
		
		public function userAskingPermissionToView(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("userAskingPermissionToView", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userStartedViewing(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("userStartedViewing", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userStoppedViewing(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("userStoppedViewing", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userStartedListening(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("userStartedListening", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function userStoppedListening(tmpObj:Object):void
		{
			dispatchEvent(new CustomEvent("userStoppedListening", false, false, tmpObj));
			tmpObj = null;
		}
		
		
		public function ignoredUser(ignoreInfo:Object):void
		{
			dispatchEvent(new CustomEvent("ignoredUser", false, false, ignoreInfo));
			ignoreInfo = null;
		}
		
		
		public function unignoredUser(ignoreInfo:Object):void
		{
			dispatchEvent(new CustomEvent("unignoredUser", false, false, ignoreInfo));
			ignoreInfo = null;
		}
		
		
		public function getBlockedUsersList(resultObj:Object):void
		{
			debugMsg("getBlockedUsersList->  resultObj: "+resultObj+"  =  "+ObjectUtil.toString(resultObj));
			
			var tmpObj:Object = resultObj;
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("onGetBlockedUsersListResult", false, false, tmpObj));
			
			tmpObj = null;
			resultObj = null;
		}
		
		
		public function onGetUserPropertyResult(resultObj:Object):void
		{
			debugMsg("onGetUserPropertyResult->  resultObj: "+resultObj+"  ok: "+resultObj.ok+"  status: "+resultObj.status+"  resultAdminType: "+resultObj.resultAdminType);
			
			var tmpObj:Object = resultObj;
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("onGetUserPropertyResult", false, false, tmpObj));
			
			tmpObj = null;
			resultObj = null;
		}
		
		
		public function onSetUserPropertyResult(resultObj:Object):void
		{
			debugMsg("onSetUserPropertyResult->  resultObj: "+resultObj+"  ok: "+resultObj.ok+"  status: "+resultObj.status);
			
			var tmpObj:Object = resultObj;
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("onSetUserPropertyResult", false, false, tmpObj));
			
			tmpObj = null;
			resultObj = null;
		}
		
		
		// deprecated
		public function getUserIP(ip:String):void
		{
			var ipInfo:Object = new Object();
			ipInfo.ip = ip;
			dispatchEvent(new CustomEvent("getUserIP", false, false, ipInfo));
			ip = null;
			ipInfo = null;
		}
		
		
		
		// TODO
		// remove and nullify event listeners etc
		public function close():void
		{
		}
		
		
		
		
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			AppWideDebug_Singleton.getInstance().newDebugMessage('NetConnectionClient', str);
			
			//trace('NetConnectionClient | ' + str);
			
			str = null;
		}	
		
		
	}// end class
}// end package