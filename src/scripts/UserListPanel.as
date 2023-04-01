import flash.events.Event;
import flash.events.SyncEvent;
import flash.net.SharedObject;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.utils.StringUtil;

import spark.components.TitleWindow;

import components.popups.UserListMenu_PopUpTitleWindow;

import events.CustomEvent;

import me.whohacked.app.AppWideDebug_Singleton;
import me.whohacked.app.AppWideEventDispatcher_Singleton;
import me.whohacked.app.IconManager_Singleton;

import scripts.net.UserListSOClient;



[Bindable]
public var userList_DP:ArrayCollection = new ArrayCollection();
public var userListSOClient:UserListSOClient;
public var usersSO:SharedObject;
public var userCmdObj:Object;
public var popUpMenu:TitleWindow;


private var __appWideEventDispatcher:AppWideEventDispatcher_Singleton;




private function userListCreationCompleteHandler(event:FlexEvent):void
{
	debugMsg("userListCreationCompleteHandler->  LOADED");
	
	__appWideEventDispatcher = AppWideEventDispatcher_Singleton.getInstance();
	__appWideEventDispatcher.addEventListener("userList_onGetUserList", userList_onGetUserList, false,0,true);
	__appWideEventDispatcher.addEventListener("userList_addUser", userList_addUser, false,0,true);
	__appWideEventDispatcher.addEventListener("userList_removeUser", userList_removeUser, false,0,true);
	//__appWideEventDispatcher.addEventListener("userList_addUser", userList_addUser, false,0,true);
	//__appWideEventDispatcher.addEventListener("userList_removeUser", userList_removeUser, false,0,true);
	__appWideEventDispatcher.addEventListener("mediaManager_allStoppedViewing", mediaManager_allStoppedViewing, false,0,true);
	__appWideEventDispatcher.addEventListener("mediaManager_allStoppedListening", mediaManager_allStoppedListening, false,0,true);
	
	//Create a Sort object to sort the ArrrayCollection.
	userList_DP.sort = new Sort();
	userList_DP.sort.fields = [new SortField("userName", true)];
	
	// Refresh the collection view to show the sort.
	userList_DP.refresh();
	
	userList_numUsers_Img.source = IconManager_Singleton.getInstance().getIcon('app_userList_users');
	
	event = null;
}


public function initUserList():void
{
	// TODO
	// separate userlist from SO
	usersSO = SharedObject.getRemote("users", parentApplication.loginPanel.nc.uri, false);
	
	//userListSOClient = new UserListSOClient();
	//usersSO.client = userListSOClient;
	//usersSO.connect(parentApplication.loginPanel.nc);
	
	/*
	if (!usersSO.hasEventListener(SyncEvent.SYNC))
	{
		usersSO.addEventListener(SyncEvent.SYNC, userListSoOnSync, false,0,true);
	}
	*/
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userVideoOn"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userVideoOn", userVideoOn, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userVideoOff"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userVideoOff", userVideoOff, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userAudioOn"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userAudioOn", userAudioOn, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userAudioOff"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userAudioOff", userAudioOff, false,0,true);
	}
	
	if (!parentApplication.loginPanel.nc.client.hasEventListener("userStartedViewing"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("userStartedViewing", userStartedViewing, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("userStoppedViewing"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("userStoppedViewing", userStoppedViewing, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("userStartedListening"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("userStartedListening", userStartedListening, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("userStoppedListening"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("userStoppedListening", userStoppedListening, false,0,true);
	}
	
	if (!__appWideEventDispatcher.hasEventListener("onGetBlockedUsersListResult"))
	{
		__appWideEventDispatcher.addEventListener("onGetBlockedUsersListResult", onGetBlockedUsersListResult, false,0,true);
	}
}


private function userListSoOnSync(event:SyncEvent):void
{
	//trace("UserList.userListSoOnSync->  ");  
	
	//stop the SO SYNC event listener once it has loaded
	if (usersSO.hasEventListener(SyncEvent.SYNC))
	{
		//trace("UserList.userListSoOnSync->  hasEventListener(SyncEvent.SYNC): "+usersSO.hasEventListener(SyncEvent.SYNC));
		//trace("UserList.userListSoOnSync->  REMOVING usersSO.SyncEvent");
		usersSO.removeEventListener(SyncEvent.SYNC, userListSoOnSync);
		//trace("UserList.userListSoOnSync->  hasEventListener(SyncEvent.SYNC): "+usersSO.hasEventListener(SyncEvent.SYNC));
	}
	
	// clean the usernames for display
	for (var i:Object in usersSO.data)
	{
		//usersSO.data[i].userName = StringUtil.trim(usersSO.data[i].userName);
		
		userListSOClient.addUser(usersSO.data[i], true);
		//trace("######## usersSO.data[i].index ###########>  usersSO.data[i]: "+usersSO.data[i]+" = "+i);
	}
	
	/*
	for (var prop:String in usersSO.data) 
	{
		trace("|_userListSoOnSync.prop> "+prop+" = "+usersSO.data[prop]);
	}
	*/
	
	// auto dock the cams after the userlist is done loading
	//parentApplication.lobby.autoDockCams();
	
	// TEST
	// update the usercount
	userList_numUsers_L.text = userList_DP.length.toString();
	
	event = null;
}


public function userList_onGetUserList(event:CustomEvent):void
{
	var eventObj:Object = event.cloneCustomEvent().eventObj;
	
	debugMsg("userList_onGetUserList->  "+eventObj);
	
	for (var i:Object in eventObj)
	{
		var tmpObj:Object = eventObj[i];
		
		//debugMsg("userList_onGetUserList->  tmpObj: "+tmpObj+"  userName: "+tmpObj.userName);
		
		// check if the users userID is your userID,
		// and define the viewed/heardByIDs arrays.
		if (tmpObj.userID == parentApplication.lobby.mediaManager.userID)
		{
			// temp set the local users acctName
			parentApplication.lobby.mediaManager.acctName = tmpObj.acctName;
			
			tmpObj.viewedByUserIDs_A = parentApplication.lobby.mediaManager.viewedByUserIDs_A;
			tmpObj.heardByUserIDs_A = parentApplication.lobby.mediaManager.heardByUserIDs_A;
			tmpObj.isMyVideoOn = parentApplication.lobby.mediaManager.isMyVideoOn;
			tmpObj.isMyAudioOn = parentApplication.lobby.mediaManager.isMyAudioOn;
			tmpObj.doNotDock = false;
		} else {
			// else this is another user
			tmpObj.isViewing = false;
			tmpObj.isListening = false;
			tmpObj.doNotDock = false;
		}
		
		tmpObj.userName = StringUtil.trim(tmpObj.userName);
		
		if (parentApplication.lobby.isUserIgnored(tmpObj.acctID, (tmpObj.acctID==0 ? tmpObj.userName : tmpObj.nonDuplicateName)))
		{
			tmpObj.isIgnored = true;
		} else {
			tmpObj.isIgnored = false;
		}
		
		// show the 'username entered room' text 
		// for the local user when they login
		if (tmpObj.userID == parentApplication.lobby.mediaManager.userID)
		{
			parentApplication.lobby.chatPanel.userEnterLeave(tmpObj.userName, "entered");
		}
		
		userList_DP.addItem(tmpObj);
		//userList_DP.refresh();
		userList_DG.invalidateList();
		
		// TODO:
		//if isUserIgnored,
		//ignoreUser
		
		//debugMsg("userList_onGetUserList->  ADDED userID: "+tmpObj.userID+"  userName: "+tmpObj.userName+"  viewedByUserIDs_A.length: "+parentApplication.lobby.mediaManager.viewedByUserIDs_A.length+" heardByUserIDs_A.length: "+parentApplication.lobby.mediaManager.heardByUserIDs_A.length+" isMyVideoOn: "+parentApplication.lobby.mediaManager.isMyVideoOn+" isMyAudioOn: "+parentApplication.lobby.mediaManager.isMyAudioOn+" to userList_DP.index: "+userList_DP.getItemIndex(tmpObj));
		
		tmpObj = null;
		i = null;
	}
	
	//parentApplication.loginPanel.nc.call("getBlockedUsers", null, parentApplication.lobby.mediaManager.clientID);
	
	// update the usercount
	userList_numUsers_L.text = userList_DP.length.toString();
	
	// auto dock the cams after the userlist is done loading.
	// TODO: autoDockCams AFTER ignores are received
	parentApplication.lobby.autoDockCams();
	
	eventObj = null;
	event = null;
}


// TODO rename
// called when a user joins the room
public function userList_addUser(event:CustomEvent):void
{
	var tmpObj:Object = event.eventObj;
	
	//debugMsg("userList_addUser->  tmpObj: "+tmpObj+"  userName: "+tmpObj.userName);
	
	// check if the users userID is your userID,
	// and define the viewed/heardByIDs arrays.
	if (tmpObj.userID == parentApplication.lobby.mediaManager.userID)
	{
		// temp set the local users acctName
		parentApplication.lobby.mediaManager.acctName = tmpObj.acctName;
		
		tmpObj.viewedByUserIDs_A = parentApplication.lobby.mediaManager.viewedByUserIDs_A;
		tmpObj.heardByUserIDs_A = parentApplication.lobby.mediaManager.heardByUserIDs_A;
		tmpObj.isMyVideoOn = parentApplication.lobby.mediaManager.isMyVideoOn;
		tmpObj.isMyAudioOn = parentApplication.lobby.mediaManager.isMyAudioOn;
		tmpObj.doNotDock = false;
	} else {
		// else this is another user
		tmpObj.isViewing = false;
		tmpObj.isListening = false;
		tmpObj.doNotDock = false;
	}
	
	tmpObj.userName = StringUtil.trim(tmpObj.userName);
	
	if (parentApplication.lobby.isUserIgnored(tmpObj.acctID, (tmpObj.acctID==0 ? tmpObj.userName : tmpObj.nonDuplicateName)))
	{
		tmpObj.isIgnored = true;
	} else {
		tmpObj.isIgnored = false;
	}
	
	// show the username entered room text 
	// for the local user when they login
	if (tmpObj.userID != parentApplication.lobby.mediaManager.userID)
	{
		parentApplication.lobby.chatPanel.userEnterLeave(tmpObj.userName, "entered");
	}
	
	// remove the onSync
	if (tmpObj.isOnSync)
	{
		delete tmpObj.isOnSync;
	}
	
	userList_DP.addItem(tmpObj);
	//userList_DP.refresh();
	userList_DG.invalidateList();
	
	// TODO:
	//if isUserIgnored,
	//ignoreUser
	
	// update the blocked users, possibly delete or move to onSync?
	//parentApplication.loginPanel.nc.call("getBlockedUsers", null, parentApplication.lobby.mediaManager.clientID);
	
	//debugMsg("userList_addUser->  ADDED userID: "+tmpObj.userID+"  userName: "+tmpObj.userName+"  viewedByUserIDs_A.length: "+parentApplication.lobby.mediaManager.viewedByUserIDs_A.length+" heardByUserIDs_A.length: "+parentApplication.lobby.mediaManager.heardByUserIDs_A.length+" isMyVideoOn: "+parentApplication.lobby.mediaManager.isMyVideoOn+" isMyAudioOn: "+parentApplication.lobby.mediaManager.isMyAudioOn+" to userList_DP.index: "+userList_DP.getItemIndex(tmpObj));
	
	// TEST
	// update the usercount
	userList_numUsers_L.text = userList_DP.length.toString();
	
	tmpObj = null;
	event = null;
}


// TODO rename
// called when a user leaves the room
public function userList_removeUser(event:CustomEvent):void
{
	//debugMsg("userList_removeUser-> event: "+event+"  userID: "+event.eventObj.userID+"  userName: "+event.eventObj.userName);
	
	if ((!event.eventObj) || 
		(!userList_DP.length)) 
		return;
	
	for (var i:Object in userList_DP)
	{
		if ((userList_DP[i]) && (userList_DP[i].userID == event.eventObj.userID))
		{
			userList_DP[i].isUsersVideoOn = false;
			userList_DP[i].isUsersAudioOn = false;
			
			// remove the user from the array which shows who is watching your cam
			if (parentApplication.lobby.mediaManager.viewedByUserIDs_A.indexOf("user_"+event.eventObj.userID) != -1)
			{
				parentApplication.lobby.mediaManager.viewedByUserIDs_A = parentApplication.lobby.mediaManager.viewedByUserIDs_A.removeItemAt(parentApplication.lobby.mediaManager.viewedByUserIDs_A.indexOf("user_"+event.eventObj.userID), 1);
			}
			
			// remove the user from the array which shows who is listening to your audio
			if (parentApplication.lobby.mediaManager.heardByUserIDs_A.indexOf("user_"+event.eventObj.userID) != -1)
			{
				parentApplication.lobby.mediaManager.heardByUserIDs_A = parentApplication.lobby.mediaManager.heardByUserIDs_A.slice(parentApplication.lobby.mediaManager.heardByUserIDs_A.indexOf("user_"+event.eventObj.userID), 1);
			}
			
			// check to see if the users cam is docked
			if (parentApplication.lobby.isUserDocked(userList_DP[i].userID))
			{
				//debugMsg("userList_removeUser->  parentApplication.lobby.dockedUserIDs_AC.length: "+parentApplication.lobby.dockedUserIDs_AC.length+"  contains(userList_DP[i]): "+parentApplication.lobby.dockedUserIDs_AC.contains("user_"+userList_DP[i]));
				parentApplication.lobby.undockCamSpot(userList_DP[i]);
			}
			
			// if the user joining/leaving is the local user
			if (event.eventObj.userID != parentApplication.lobby.mediaManager.userID)
			{
				// show the user joined/left the room message
				parentApplication.lobby.chatPanel.userEnterLeave(event.eventObj.userName, "left");
			}
			
			//debugMsg("userList_removeUser->  REMOVING user_"+userList_DP[i].userID+"  userName: "+userList_DP[i].userName);
			userList_DP.removeItemAt(userList_DP.getItemIndex(userList_DP[i]));
		}
	}
	
	userList_DP.refresh();
	userList_DG.invalidateList();
	
	// TEST
	// update the usercount
	userList_numUsers_L.text = userList_DP.length.toString();
	
	event = null;
	i = null;
}





public function mediaManager_allStoppedViewing(event:Event):void
{
	allStoppedViewingListening(true, false);
	event = null;
}


public function mediaManager_allStoppedListening(event:Event):void
{
	allStoppedViewingListening(false, true);
	event = null;
}


private function userVideoOn(event:CustomEvent):void
{
	userMediaOnOff(event.eventObj.userID, "video", true);
	event = null;
}


private function userVideoOff(event:CustomEvent):void
{
	userMediaOnOff(event.eventObj.userID, "video", false);
	event = null;
}


private function userAudioOn(event:CustomEvent):void
{
	userMediaOnOff(event.eventObj.userID, "audio", true);
	event = null;
}


private function userAudioOff(event:CustomEvent):void
{
	userMediaOnOff(event.eventObj.userID, "audio", false);
	event = null;
}


public function userMediaOnOff(userID:Number, media:String, onOff:Boolean):void
{
	debugMsg("userMediaOnOff->  userID: "+userID+"  media: "+media+"  onOff: "+onOff);
	
	for (var i:Object in userList_DP)
	{
		if (userList_DP[i].userID == userID)
		{
			switch (media)
			{
				case "video":
					if (onOff)
					{
						userList_DP[i].isUsersVideoOn = true;
					} else {
						userList_DP[i].isUsersVideoOn = false;
					}
					break;
				case "audio":
					if (onOff)
					{
						userList_DP[i].isUsersAudioOn = true;
					} else {
						userList_DP[i].isUsersAudioOn = false;
					}
					break;
			}
			
			userList_DP.refresh();
			userList_DG.invalidateList();
			
			break;
		}
	}
	
	media = null;
	i = null;
}


private function userStartedViewing(event:CustomEvent):void
{
	// TEMP:
	// send a debug msg to chat
	setIsViewingListening(event.eventObj.userID, "video", true);
	event = null;
}


private function userStoppedViewing(event:CustomEvent):void
{
	setIsViewingListening(event.eventObj.userID, "video", false);
	event = null;
}


private function userStartedListening(event:CustomEvent):void
{
	setIsViewingListening(event.eventObj.userID, "audio", true);
	event = null;
}


private function userStoppedListening(event:CustomEvent):void
{
	setIsViewingListening(event.eventObj.userID, "audio", false);
	event = null;
}


private function onGetBlockedUsersListResult(event:CustomEvent):void
{
	debugMsg("onGetBlockedUsersListResult->  blockedUsersListObj: "+event.eventObj);
	
	//setBlockedUsers(event.cloneCustomEvent().eventObj);
	
	event = null;
}


public function setIsViewingListening(userID:Number, prop:String, val:Boolean):void
{
	for (var i:Object in userList_DP)
	{
		if (userList_DP[i].userID == userID)
		{
			debugMsg("setIsViewingListening->  userID: "+userID+"  userName: "+userList_DP[i].userName+"  prop: "+prop+"  val: "+val);
			
			switch (prop)
			{
				case "video":
					if (val)
					{
						userList_DP[i].isViewing = true;
					} else {
						userList_DP[i].isViewing = false;
					}
					break;
				case "audio":
					if (val)
					{
						userList_DP[i].isListening = true;
					} else {
						userList_DP[i].isListening = false;
					}
					break;
			}
			
			userList_DP.refresh();
			userList_DG.invalidateList();
			
			break;
		}
	}
	
	prop = null;
	i = null;
}


public function allStoppedViewingListening(video:Boolean, audio:Boolean):void
{
	for (var i:int = 0; i < userList_DP.length; ++i) 
	{
		if (video)
		{
			userList_DP[i].isViewing = false;
		}
		
		if (audio)
		{
			userList_DP[i].isListening = false;
		}
	}
	
	//audio = null;
	//video = null;
}



// TODO
// close the ignored users cam if docked, and
// stop ignored user from viewing your cam
public function ignoredUser(ignoreInfo:Object):void
{
	debugMsg("ignoredUser->  whoIgnoredName: "+ignoreInfo.whoIgnoredName+"  ignoredWhoName: "+ignoreInfo.ignoredWhoName);
	
	var isAGuestIgnoring:Boolean = (ignoreInfo.whoIgnoredAcctID == 0);
	var isIgnoringAGuest:Boolean = (ignoreInfo.ignoredWhoAcctID == 0);
	var isLocalClientIgnoring:Boolean = (((ignoreInfo.whoIgnoredAcctID != 0) && 
										(ignoreInfo.whoIgnoredAcctID == parentApplication.lobby.mediaManager.acctID)) ||
										(ignoreInfo.whoIgnoredName == parentApplication.lobby.mediaManager.userName));
	var isIgnoringLocalClient:Boolean = (((ignoreInfo.ignoredWhoAcctID != 0) && 
										(ignoreInfo.ignoredWhoAcctID == parentApplication.lobby.mediaManager.acctID)) ||
										(ignoreInfo.ignoredWhoName == parentApplication.lobby.mediaManager.userName));
	
	// find the ignored user
	for (var i:int = 0; i < userList_DP.length; ++i) 
	{
		if ((!isLocalClientIgnoring) && 
			(((!isAGuestIgnoring) && 
			(userList_DP[i].acctID == ignoreInfo.whoIgnoredAcctID)/* && 
			(ignoreInfo.whoIgnoredAcctID != parentApplication.lobby.mediaManager.acctID)*/) ||
			((isAGuestIgnoring) && 
			(userList_DP[i].userName == ignoreInfo.whoIgnoredName)/* && 
			(ignoreInfo.whoIgnoredName != parentApplication.lobby.mediaManager.userName)*/)))
		{
			userList_DP[i].hasBlocked = true;
			
			if (parentApplication.lobby.isUserDocked(userList_DP[i].userID))
			{
				// TEMP:
				parentApplication.loginPanel.nc.call('mediaManager.stopViewingUser', null, parentApplication.lobby.mediaManager.clientID, userList_DP[i].userID);
				parentApplication.loginPanel.nc.call('mediaManager.stopListeningToUser', null, parentApplication.lobby.mediaManager.clientID, userList_DP[i].userID);
				parentApplication.lobby.undockCamSpot(userList_DP[i]);
			}
			
			// TEMP
			setIsViewingListening(userList_DP[i].userID, "video", false);
			setIsViewingListening(userList_DP[i].userID, "audio", false);
		}
		
		if ((!isIgnoringLocalClient) && 
			(((!isIgnoringAGuest) &&
			(userList_DP[i].acctID == ignoreInfo.ignoredWhoAcctID)/* || 
			(ignoreInfo.ignoredWhoAcctID != parentApplication.lobby.mediaManager.acctID)*/) ||
			((isIgnoringAGuest) && 
			(userList_DP[i].userName == ignoreInfo.ignoredWhoName)/* || 
			(ignoreInfo.ignoredWhoName != parentApplication.lobby.mediaManager.userName)*/)))
		{
			userList_DP[i].isIgnored = true;
			
			if (parentApplication.lobby.isUserDocked(userList_DP[i].userID))
				parentApplication.lobby.undockCamSpot(userList_DP[i]);
			
			// TEMP
			setIsViewingListening(userList_DP[i].userID, "video", false);
			setIsViewingListening(userList_DP[i].userID, "audio", false);
			
			//userList_DP[i][(isIgnoringLocalClient ? "hasBlocked" : "isIgnored")] = true;
			/*
			// someone blocked the local client
			if (((ignoreInfo.ignoredWhoAcctID != 0) && 
				(ignoreInfo.ignoredWhoAcctID == parentApplication.lobby.mediaManager.acctID)) ||
				(ignoreInfo.ignoredWhoName == parentApplication.lobby.mediaManager.userName))
			{
				userList_DP[i].hasBlocked = true;
				
				continue;
			}
			
			// if the local client blocked someone
			if (((ignoreInfo.whoIgnoredAcctID != 0) && 
				(ignoreInfo.whoIgnoredAcctID == parentApplication.lobby.mediaManager.acctID)) ||
				(ignoreInfo.whoIgnoredName == parentApplication.lobby.mediaManager.userName))
			{
				userList_DP[i].isIgnored = true;
				
				continue;
			}
			*/
			
			//break;
		}
		
		/*
		// if the local client blocked someone
		if (((ignoreInfo.whoIgnoredAcctID != 0) && 
			(ignoreInfo.whoIgnoredAcctID == parentApplication.lobby.mediaManager.acctID)) ||
			(ignoreInfo.whoIgnoredName == parentApplication.lobby.mediaManager.userName))
		{
			userList_DP[i].isIgnored = true;
			
			continue;
		}
		
		// if the local client blocked this user
		if (((userList_DP[i].acctID != 0) && 
			(userList_DP[i].acctID == ignoreInfo.whoIgnoredAcctID)) ||
			(userList_DP[i].userName == ignoreInfo.whoIgnoredName))
		{
			userList_DP[i].isIgnored = true;
		}
		
		// ----------------------------------------
		// this user item is the local client
		if ((userList_DP[i].acctID != 0) && 
			(userList_DP[i].ignoredWhoAcctID == parentApplication.lobby.mediaManager.acctID))
		{
			// if this user blocked you
			if ((ignoreInfo.whoIgnoredAcctID == userList_DP[i].acctID) || 
				(ignoreInfo.whoIgnoredName == userList_DP[i].userName))
			{
				userList_DP[i].hasBlocked = true;
			}
		} else {
		// this user item is another user
			// if this user is blocked
			if (((userList_DP[i].acctID != 0) && 
				(userList_DP[i].acctID == ignoreInfo.ignoredWhoAcctID)) ||
				(userList_DP[i].userName == ignoreInfo.ignoredWhoName))
			{
				userList_DP[i].isIgnored = true;
			}
		}*/
	}
	
	userList_DP.refresh();
	userList_DG.invalidateDisplayList();
	
	//i = null;
	//isIgnoringAGuest = null;
	//isAGuestIgnoring = null;
	ignoreInfo = null;
}


public function unignoredUser(ignoreInfo:Object):void
{
	debugMsg("unignoredUser->  whoIgnoredName: "+ignoreInfo.whoIgnoredName+"  ignoredWhoName: "+ignoreInfo.ignoredWhoName);
	
	var isAGuestUnignoring:Boolean = (ignoreInfo.whoIgnoredAcctID == 0);
	var isUnignoringAGuest:Boolean = (ignoreInfo.ignoredWhoAcctID == 0);
	
	for (var i:Object in userList_DP)
	{
		if (((!isAGuestUnignoring) && 
			(userList_DP[i].acctID == ignoreInfo.whoIgnoredAcctID)/* && 
			(ignoreInfo.whoIgnoredAcctID != parentApplication.lobby.mediaManager.acctID)*/) ||
			((isAGuestUnignoring) && 
			(userList_DP[i].userName == ignoreInfo.whoIgnoredName)/* && 
			(ignoreInfo.whoIgnoredName != parentApplication.lobby.mediaManager.userName)*/))
		{
			userList_DP[i].hasBlocked = false;
		}
		
		if (((!isUnignoringAGuest) &&
			(userList_DP[i].acctID == ignoreInfo.ignoredWhoAcctID)/* && 
			(ignoreInfo.ignoredWhoAcctID != parentApplication.lobby.mediaManager.acctID)*/) ||
			((isUnignoringAGuest) && 
			(userList_DP[i].userName == ignoreInfo.ignoredWhoName)/* && 
			(ignoreInfo.ignoredWhoName != parentApplication.lobby.mediaManager.userName)*/))
		{
			userList_DP[i].isIgnored = false;
		}
	}
	
	userList_DP.refresh();
	userList_DG.invalidateList();
	
	i = null;
	//isUnignoringAGuest = null;
	//isAGuestUnignoring = null;
	ignoreInfo = null;
}


public function setBlockedUsers(blockedUsers:Object):void
{
	debugMsg("setBlockedUsers->  blockedUsers.length: "+blockedUsers.length);
	for (var i:Object in blockedUsers)
	{
		debugMsg("setBlockedUsers->  blockedUsers[i]: "+blockedUsers[i]+"  i: "+i);
		/*for (var y:* in blockedUsers[i])
		{
			debugMsg("setBlockedUsers->  blockedUsers[i][y]: "+blockedUsers[i][y]+"  y: "+y);
		}*/
		
		// TODO fix/replace
		
		for (var x:Object in userList_DP)
		{
			if (blockedUsers[i].ignoredWhoAcctID == 0)
			{
				if (userList_DP[x].userName == blockedUsers[i].ignoredWhoName)
				{
					userList_DP[x].isIgnored = true;
				}
				if (userList_DP[x].userName == blockedUsers[i].whoIgnoredName)
				{
					userList_DP[x].hasBlocked = true;
				}
			} else {
				if (userList_DP[x].acctID == blockedUsers[i].ignoredWhoAcctID)
				{
					userList_DP[x].isIgnored = true;
				}
			}
			
			if (blockedUsers[i].whoIgnoredAcctID == 0)
			{
				if (userList_DP[x].userName == blockedUsers[i].whoIgnoredName)
				{
					userList_DP[x].hasBlocked = true;
				}
			} else {
				if (userList_DP[x].acctID == blockedUsers[i].whoIgnoredAcctID)
				{
					userList_DP[x].hasBlocked = true;
				}
			}
		}
		
		x = null;
		//y = null;
	}
	
	userList_DP.refresh();
	userList_DG.invalidateList();
	
	i = null;
	blockedUsers = null;
}


public function getUserObj(userID:Number):Object
{
	for (var i:int = 0; i < userList_DP.length; ++i) 
	{
		if (userList_DP[i].userID == userID)
		{
			//debugMsg("getUserObj->  userInfoObj: "+userList_DP[i]);
			return userList_DP[i];
		}
	}
	
	return {};
}


// dispatched when a user is clicked
private function userList_DG_itemClickHandler(event:ListEvent):void
{
	PopUpManager.createPopUp(parentApplication.lobby, UserListMenu_PopUpTitleWindow, false);
	
	event = null;
}


// dispatched when a user is double clicked
private function userList_DG_itemDoubleClickHandler(event:ListEvent):void
{
	if (parentApplication.lobby.openPopUps_AC.contains(popUpMenu))
	{
		parentApplication.lobby.openPopUps_AC.removeItemAt(parentApplication.lobby.openPopUps_AC.getItemIndex(popUpMenu));
	}
	
	PopUpManager.removePopUp(popUpMenu);
	
	//trace("isUserIgnored:  "+parentApplication.lobby.isUserIgnored(event.currentTarget.selectedItem.acctID, (event.currentTarget.selectedItem.acctID==0 ? event.currentTarget.selectedItem.userName : event.currentTarget.selectedItem.nonDuplicateName)));
	
	if (event.currentTarget.selectedItem.doNotDock==true)
	{
		for (var i:int = 0; i < userList_DP.length; ++i) 
		{
			if (userList_DP[i].userID == event.currentTarget.selectedItem.userID)
			{
				userList_DP[i].doNotDock = false;
				break;
			}
		}
	}
	
	if (!userList_DG.selectedItem.hasBlocked && !parentApplication.lobby.isUserIgnored(event.currentTarget.selectedItem.acctID, (event.currentTarget.selectedItem.acctID==0 ? event.currentTarget.selectedItem.userName : event.currentTarget.selectedItem.nonDuplicateName)))
	{
		if (event.currentTarget.selectedItem.isUsersVideoOn || event.currentTarget.selectedItem.isUsersAudioOn)
			parentApplication.lobby.dockCamSpot(event.currentTarget.selectedItem);
		
		//if ((parentApplication.lobby.camSpot6.isPlayingVideo && parentApplication.lobby.camSpot6.userInfoObj.isUsersVideoOn) || (parentApplication.lobby.camSpot6.isPlayingAudio && parentApplication.lobby.camSpot6.userInfoObj.isUsersAudioOn))
		//{
		// already playing media in the main cam, so dock the cam if possible
		//var tmpUserObj:Object = parentApplication.lobby.camSpot6.userInfoObj;
		//parentApplication.lobby.dockCamSpot(tmpUserObj);
		//parentApplication.lobby.camSpot6.attachUser(event.currentTarget.selectedItem);
		//tmpUserObj = null;
		//} else {
		// not playing media in the main cam, so attach it like normal
		//parentApplication.lobby.camSpot6.attachUser(event.currentTarget.selectedItem);
		//}
	}
	
	popUpMenu = null;
	event = null;
}


public function close():void
{
	if (usersSO)
	{
		usersSO.close();
		usersSO.clear();
		
		if (usersSO.hasEventListener(SyncEvent.SYNC))
		{
			usersSO.removeEventListener(SyncEvent.SYNC, userListSoOnSync);
		}
		
		usersSO = null;
	}
	
	if (parentApplication.loginPanel.nc.client.hasEventListener("userStartedViewing"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("userStartedViewing", userStartedViewing);
	}
	if (parentApplication.loginPanel.nc.client.hasEventListener("userStoppedViewing"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("userStoppedViewing", userStoppedViewing);
	}
	if (parentApplication.loginPanel.nc.client.hasEventListener("userStartedListening"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("userStartedListening", userStartedListening);
	}
	if (parentApplication.loginPanel.nc.client.hasEventListener("userStoppedListening"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("userStoppedListening", userStoppedListening);
	}
	if (__appWideEventDispatcher.hasEventListener("onGetBlockedUsersListResult"))
	{
		__appWideEventDispatcher.removeEventListener("onGetBlockedUsersListResult", onGetBlockedUsersListResult);
	}
	
	if (parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userVideoOn"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("mediaSOClient_userVideoOn", userVideoOn);
	}
	if (parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userVideoOff"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("mediaSOClient_userVideoOff", userVideoOff);
	}
	if (parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userAudioOn"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("mediaSOClient_userAudioOn", userAudioOn);
	}
	if (parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userAudioOff"))
	{
		parentApplication.loginPanel.nc.client.removeEventListener("mediaSOClient_userAudioOff", userAudioOff);
	}
	
	userList_DG.selectedItem = null;
	userList_DP.removeAll();
	
	userList_numUsers_L.text = "0";
	
	userCmdObj = null;
	popUpMenu = null;
}








private function debugMsg(str:String):void
{
	AppWideDebug_Singleton.getInstance().newDebugMessage(this.id, str);
	str = null;
}


