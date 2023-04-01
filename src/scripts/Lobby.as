/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
import mx.collections.ArrayCollection;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.utils.ObjectUtil;

import components.popups.BanList_PopUpTitleWindow;
import components.popups.BlockList_PopUpTitleWindow;
import components.popups.PrivateMessage_PopUpTitleWindow;

import events.CustomEvent;

import me.whohacked.app.AppWideDebug_Singleton;
import me.whohacked.app.AppWideEventDispatcher_Singleton;
import me.whohacked.app.AppWide_Singleton;
import me.whohacked.app.LocalSOManager_Singleton;

import scripts.MediaManager;



public var mediaManager:MediaManager = new MediaManager();
public var dockedUserIDs_AC:ArrayCollection;
public var openPopUps_AC:ArrayCollection;
public var tmpObj:Object;
public var tmpStr:String;

private var __appWideSingleton:AppWide_Singleton;
private var __appWideEventDispatcher:AppWideEventDispatcher_Singleton;




private function preinitializeHandler(event:FlexEvent):void
{
	__appWideSingleton = AppWide_Singleton.getInstance();
	__appWideEventDispatcher = AppWideEventDispatcher_Singleton.getInstance();
	
	dockedUserIDs_AC = __appWideSingleton.dockedUserIDs_AC;
	openPopUps_AC = __appWideSingleton.openPopUps_AC;
	
	event = null;
}


private function lobbyCreationCompleteHandler(event:FlexEvent):void
{
	trace("|###| Lobby |###|>  LOADED");
	
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
	/*if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userStartedViewing"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userStartedViewing", userStartedViewing, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userStoppedViewing"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userStoppedViewing", userStartedListening, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userStartedListening"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userStartedListening", userStartedListening, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("mediaSOClient_userStoppedListening"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("mediaSOClient_userStoppedListening", userStoppedListening, false,0,true);
	}*/
	if (!parentApplication.loginPanel.nc.client.hasEventListener("ignoredUser"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("ignoredUser", ignoredUser, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("unignoredUser"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("unignoredUser", unignoredUser, false,0,true);
	}
	if (!parentApplication.loginPanel.nc.client.hasEventListener("receiveBannedUsers"))
	{
		parentApplication.loginPanel.nc.client.addEventListener("receiveBannedUsers", receiveBannedUsers, false,0,true);
	}
	
	if (!parentApplication.loginPanel.nc.client.hasEventListener("receivePrivateMessage"))
		parentApplication.loginPanel.nc.client.addEventListener("receivePrivateMessage", receivePrivateMessage, false,0,true);
	
	if (!__appWideEventDispatcher.hasEventListener("onGetBlockedUsersListResult"))
		__appWideEventDispatcher.addEventListener("onGetBlockedUsersListResult", onGetBlockedUsersListResultHandler, false,0,true);
	
	/*
	if (!__appWideEventDispatcher.hasEventListener("dockUser"))
		__appWideEventDispatcher.addEventListener('dockUser', dockUser, false,0,true);
	
	if (!__appWideEventDispatcher.hasEventListener("undockUser"))
		__appWideEventDispatcher.addEventListener('undockUser', undockUser, false,0,true);
	
	if (!__appWideEventDispatcher.hasEventListener("userList_addUser"))
		__appWideEventDispatcher.addEventListener('userList_addUser', userList_addUser, false,0,true);
	
	if (!__appWideEventDispatcher.hasEventListener("userList_removeUser"))
		__appWideEventDispatcher.addEventListener('userList_removeUser', userList_removeUser, false,0,true);
	*/
	
	event = null;
}


public function initLobby():void
{
	chatPanel.showIntroText();
	
	//this.horizontalCenter = 0;
	this.x = 0;
	this.y = 0;
}


// DONT CLEAR THE CAMSPOT UNTIL BOTH VIDEO AND AUDIO ARE OFF
private function userVideoOn(event:CustomEvent):void
{
	for (var i:Object in userListPanel.userList_DP)
	{
		if (userListPanel.userList_DP[i].userID == event.eventObj.userID)
		{
			userListPanel.userList_DP[i].isUsersVideoOn = true;
			
			userListPanel.userList_DP.refresh();
			userListPanel.invalidateDisplayList();
			
			// auto-dock when someone turns their video on
			if ((dockedUserIDs_AC.length < 18) && (__appWideSingleton.appInfoObj.isAutoFillCamsChecked) && 
				(!isUserIgnored(userListPanel.userList_DP[i].acctID, (userListPanel.userList_DP[i].acctID==0 ? userListPanel.userList_DP[i].userName : userListPanel.userList_DP[i].nonDuplicateName))) && 
				(!userListPanel.userList_DP[i].hasBlocked))
			{
				dockCamSpot(userListPanel.userList_DP[i]);
			}
			
			break;
		}
	}
	i = null;
	event = null;
}


private function userVideoOff(event:CustomEvent):void
{
	//trace("Lobby.userVideoOff>  userID: "+event.eventObj.userID+"  isUserDocked: "+isUserDocked(event.eventObj.userID));
	
	for (var i:Object in userListPanel.userList_DP)
	{
		if (userListPanel.userList_DP[i].userID == event.eventObj.userID)
		{
			userListPanel.userList_DP[i].isUsersVideoOn = false;
			
			userListPanel.userList_DP.refresh();
			//userListPanel.invalidateDisplayList();
			userListPanel.validateNow();
			
			if (isUserDocked(event.eventObj.userID))
			{
				undockCamSpot(event.cloneCustomEvent().eventObj);
			}
			
			break;
		}
	}
	
	i = null;
	event = null;
}


private function userAudioOn(event:CustomEvent):void
{
	// TODO dock user
	for (var i:Object in userListPanel.userList_DP)
	{
		if (userListPanel.userList_DP[i].userID == event.eventObj.userID)
		{
			userListPanel.userList_DP[i].isUsersAudioOn = true;
			
			userListPanel.userList_DP.refresh();
			userListPanel.invalidateDisplayList();
			
			break;
		}
	}
	
	i = null;
	event = null;
}


private function userAudioOff(event:CustomEvent):void
{
	for (var i:Object in userListPanel.userList_DP)
	{
		if (userListPanel.userList_DP[i].userID == event.eventObj.userID)
		{
			userListPanel.userList_DP[i].isUsersAudioOn = false;
			
			userListPanel.userList_DP.refresh();
			userListPanel.invalidateDisplayList();
			
			// TODO: undock any users that turned both their video and audio off
			
			break;
		}
	}
	
	i = null;
	event = null;
}


public function whichCamSpot(userID:Number):String
{
	var camSpot:String;
	
	for (var x:int = 1; x <= 18; ++x)
	{
		if (parentApplication.lobby["camSpot"+x].userInfoObj.userID == userID)
		{
			camSpot = 'camSpot'+x;
			break;
		} else {
			camSpot = 'notDocked';
		}
	}
	
	return camSpot;
}


private function dockUser(event:CustomEvent):void
{
	if (isUserDocked(event.eventObj.userID)) return;
	
	dockCamSpot(event.cloneCustomEvent().eventObj, 'newUserSelected');
	
	event = null;
}


private function undockUser(event:CustomEvent):void
{
	if (!isUserDocked(event.eventObj.userID)) return;
	
	undockCamSpot(event.cloneCustomEvent().eventObj);
	
	event = null;
}


public function dockCamSpot(userObj:Object, fromCamSpot:String="autoDock"):void
{
	var isDocked:Boolean = isUserDocked(userObj.userID);
	
	// add the 'user_X' userID to the dockedUserIDs_AC array
	if (!isDocked) 
		dockedUserIDs_AC.addItem("user_"+userObj.userID);
	else
		// exit the function if the user is already docked
		return;
	
	var fromCamSpot:String = whichCamSpot(userObj.userID);
	var toCamSpot:String = userObj.toCamSpot;
	
	debugMsg("dockCamSpot->  userID: "+userObj.userID+"  fromCamSpot: "+fromCamSpot+"  toCamSpot: "+userObj.toCamSpot+"  isUserDocked: "+isDocked);
	
	// if toCamSpot was defined by switchCamSpot
	if ((toCamSpot!=null) && (toCamSpot.indexOf('camSpot') != -1))
	{
		userObj.toCamSpot = "";
		userObj.fromCamSpot = "";
		
		// attach to the blank cam
		parentApplication.lobby[toCamSpot].attachUser(userObj);
	} else {
		// if the main camspot is empty
		if (camSpot6.userInfoObj.userID == 0)
		{
			// attach to the main cam
			camSpot6.attachUser(userObj);
		} else {
			// find an empty camspot
			for (var x:int = 1; x <= __appWideSingleton.camSpotIDs_A.length; ++x)
			{
				// if the cam spot is blank
				if (parentApplication.lobby["camSpot"+x].userInfoObj.userID == 0)
				{
					// attach to the blank cam
					parentApplication.lobby["camSpot"+x].attachUser(userObj);
					
					break;
				}
			}
		}
	}
}


public function undockCamSpot(userObj:Object, doNotAutoDock:Boolean=false):void
{
	// remove the userID from the dockedUserIDs_AC array
	if (isUserDocked(userObj.userID))
		dockedUserIDs_AC.removeItemAt(dockedUserIDs_AC.getItemIndex("user_"+userObj.userID));
	else
		// exit the function if the user is not docked
		return;
	
	for (var x:int = 1; x <= 18; ++x)
	{
		if (parentApplication.lobby["camSpot"+x].userInfoObj.userID == userObj.userID)
		{
			debugMsg("undockCamSpot->  CLEARING  camSpot"+x+"  userID: "+userObj.userID+"  isUserDocked: "+isUserDocked(userObj.userID));
			
			parentApplication.lobby["camSpot"+x].clearCamSpot();
			
			// TEST
			if (!doNotAutoDock)
				autoDockCams();
			
			break;
		}
	}
}


// NEW
public function switchCamSpot(userObj:Object):void
{
	// exit the function if the user is not docked
	if (!isUserDocked(userObj.userID)) return;
	
	var fromCamSpot:String = userObj.fromCamSpot ? userObj.fromCamSpot : whichCamSpot(userObj.userID);
	var toCamSpot:String = userObj.toCamSpot ? userObj.toCamSpot : findEmptyCamSpot();
	
	debugMsg("switchCamSpot->  SWITCHING CAMS  userID: "+userObj.userID+"  fromCamSpot: "+fromCamSpot+"  toCamSpot: "+toCamSpot);
	
	if (toCamSpot == null) return;
	
	// get the current userInfoObj from the fromCamSpot
	var fromCamSpotUserObj:Object = parentApplication.lobby[fromCamSpot].userInfoObj;
	var toCamSpotUserObj:Object = parentApplication.lobby[toCamSpot].userInfoObj;
	fromCamSpotUserObj.fromCamSpot = fromCamSpot;
	fromCamSpotUserObj.toCamSpot = toCamSpot;
	
	// undock the user from the fromCamSpot
	if (fromCamSpotUserObj.userID == userObj.userID)
		undockCamSpot(fromCamSpotUserObj, true);
	
	// if the toCamSpot is not empty, undock its user
	if (toCamSpotUserObj.userID != 0) 
		undockCamSpot(toCamSpotUserObj, true);
	
	// dock the user from the fromCamSpot to the toCamSpot
	if (userObj.toCamSpot) 
	{
		dockCamSpot(fromCamSpotUserObj);
	}
	
	// dock the user from the toCamSpot to the fromCamSpot
	if (toCamSpotUserObj.userID != 0)
	{
		toCamSpotUserObj.toCamSpot = fromCamSpot;
		
		dockCamSpot(toCamSpotUserObj);
	}
	
	userObj = null;
}


public function switchToMain(userObj:Object):void
{
	// exit the function if the user is not docked
	if (!isUserDocked(userObj.userID)) return;
	
	// exit the function if the user is already in the main cam
	var fromCamSpot:String = whichCamSpot(userObj.userID);
	
	if (fromCamSpot == 'camSpot6') return;
	
	debugMsg("switchToMain->  SWITCHING TO MAIN  userID: "+userObj.userID+"  fromCamSpot: "+fromCamSpot);
	
	// get the current userInfoObj from the main cam
	var tmpUserObj:Object = camSpot6.userInfoObj;
	//tmpUserObj.toCamSpot = fromCamSpot;
	
	// undock the user that is in the camspot being switched
	if (parentApplication.lobby[fromCamSpot].userInfoObj.userID == userObj.userID)
		undockCamSpot(userObj, true);
	
	// if the main cam is not empty, undock its user
	if (tmpUserObj.userID != 0) 
		undockCamSpot(tmpUserObj, true);
	
	// dock the user to the main cam, as it should be empty
	dockCamSpot(userObj);
	
	// dock the previous main cams user to any empty camspot
	if (tmpUserObj.userID != 0) 
		dockCamSpot(tmpUserObj);
}


public function findEmptyCamSpot():String
{
	for (var i:int = 1; i <= __appWideSingleton.camSpotIDs_A.length; ++i) 
	{
		if (this['camSpot'+i].userInfoObj.userID == 0)
		{
			return 'camSpot'+i;
		}
	}
	
	return null;
}


public function isUserDocked(userID:Number):Boolean
{
	var isDocked:Boolean = dockedUserIDs_AC.contains("user_" + userID);
	
	debugMsg("isUserDocked->  userID: " + userID + "  isDocked: " + isDocked);
	
	return isDocked;
}




public function autoDockCams():void
{
	if (__appWideSingleton.appInfoObj.isAutoFillCamsChecked)
	{
		/*
		debugMsg("autoDockCams->  autoFillCamsOnJoin_CB: "+parentApplication.loginPanel.autoFillCamsOnJoin_CB.selected+"  userList_DP.length: "+userListPanel.userList_DP.length);
		
		debugMsg("autoDockCams->  userName: "+userListPanel.userList_DP[i].userName+"  isUsersVideoOn: "+userListPanel.userList_DP[i].isUsersVideoOn);
		*/
		
		// auto-dock and play a specific accounts cam
		if (__appWideSingleton.appInfoObj.isRoomHostOnMainChecked == true)
		{
			for (var o:Object in userListPanel.userList_DP)
			{
				if ((userListPanel.userList_DP[o].adminType == "rh") &&
					(userListPanel.userList_DP[o].isUsersVideoOn) &&
					(userListPanel.userList_DP[o].doNotDock==false))
				{
					dockCamSpot(userListPanel.userList_DP[o]);
					break;
				}
			}
			
			o = null;
		}
		
		// create an array or object with all the userIDs of users with their video on,
		// then look through all empty camspots and dock random users. create a temp array for
		// the user objects of each user that was docked, so it does not try to dock them again
		var tmpDockedUsers_A:Array = [];
		var usersWithVideoOn_A:Array = [];
		
		// add everyone with video on to usersWithVideoOn_A
		// who is not already docked.
		for (var i:int = 0; i < userListPanel.userList_DP.length; ++i) 
		{
			if ((userListPanel.userList_DP[i].isUsersVideoOn) &&
				(userListPanel.userList_DP[i].doNotDock==false) &&
				(!isUserDocked(userListPanel.userList_DP[i].userID)))
			{
				// add the 'user_X' userID to the dockedUserIDs_AC array
				usersWithVideoOn_A.push(userListPanel.userList_DP[i]);
			}
		}
		
		// randomize the array
		var arr2:Array = [];
		while (usersWithVideoOn_A.length > 0)
		{
			arr2.push(usersWithVideoOn_A.splice(Math.round(Math.random() * (usersWithVideoOn_A.length - 1)), 1)[0]);
		}
		
		usersWithVideoOn_A = arr2;
		
		// dock users from usersWithVideoOn_A array of random user objects
		for (i = 0; i < usersWithVideoOn_A.length; ++i) 
		{
			// BROKEN
			// i-- will just loop back to the same user that failed the if
			
			// find another user if this user was already docked
			/*if (tmpDockedUsers_A.indexOf(usersWithVideoOn_A[i])!=-1)
			{
			i = randomMinMax(0,usersWithVideoOn_A.length-1);
			break;
			}
			*/
			// randomize 
			//i = Math.random() * userListPanel.userList_DP.length;
			//i = randomMinMax(0,usersWithVideoOn_A.length-1);
			
			//debugMsg('Lobby.autoDockCams','RANDOM  i: '+i+"  tmpDockedUsers_A.indexOf: "+tmpDockedUsers_A.indexOf(usersWithVideoOn_A[i]));
			
			// stop the function when the cams are full
			if (dockedUserIDs_AC.length == 18) return;
			
			var userObj:Object = usersWithVideoOn_A[i];
			
			// make sure this user is not processed again
			//tmpDockedUsers_A.push(userObj);
			
			// if the user is not blocked then dock their video
			if ((!isUserIgnored(userObj.acctID, (userObj.acctID==0 ? userObj.userName : userObj.nonDuplicateName))) && 
				(!userObj.hasBlocked))
			{
				dockCamSpot(userObj);
			}
			
			userObj = null;
		}
		
		function randomMinMax(min:Number, max:Number):Number
		{
			return min + (max - min) * Math.round(Math.random());
		}
		
		/*		//for (i = 1; i <= userList_DP.length; i++) { if (userList_DP[i].hasVideoOn) { doSomething } else { i-- };
		var indexes:Vector.<uint> = new Vector(); 
		for(var i:int = 0, len:int = userListPanel.userList_DP.length; i<len; i++) 
		{ 
		indexes.addItem(i); 
		}*/
		/*		var cloneCopy:Array = userListPanel.userList_DP.source.concat(); 
		while(cloneCopy.length)
		{ 
		var randomIndex:int= Math.random()*cloneCopy.length; 
		var randomEntry:Object = cloneCopy.splice(randomIndex,1);
		if ((!dockedUserIDs_AC.contains("user_"+userListPanel.userList_DP[i].userID)) && (userListPanel.userList_DP[i].isUsersVideoOn) && (!isUserIgnored(userListPanel.userList_DP[i].acctID,(userListPanel.userList_DP[i].acctID==0?userListPanel.userList_DP[i].userName:userListPanel.userList_DP[i].nonDuplicateName))) && (!userListPanel.userList_DP[i].hasBlocked))
		{
		dockCamSpot(userListPanel.userList_DP[i]);
		}
		}*/
		
		arr2 = null;
		usersWithVideoOn_A = null;
		tmpDockedUsers_A = null;
	}
}


public function ignoredUser(event:CustomEvent):void
{
	debugMsg("ignoredUser->  whoIgnoredName: "+event.eventObj.whoIgnoredName+"  whoIgnoredAcctID: "+event.eventObj.whoIgnoredAcctID+"  ignoredWhoName: "+event.eventObj.ignoredWhoName+"  ignoredWhoAcctID: "+event.eventObj.ignoredWhoAcctID);
	
	var ignoreInfo:Object = event.cloneCustomEvent().eventObj;
	var isAGuestIgnoring:Boolean = (ignoreInfo.whoIgnoredAcctID == 0);
	var isIgnoringAGuest:Boolean = (ignoreInfo.ignoredWhoAcctID == 0);
	var isLocalClientIgnoring:Boolean = (((ignoreInfo.whoIgnoredAcctID != 0) && 
										(ignoreInfo.whoIgnoredAcctID == parentApplication.lobby.mediaManager.acctID)) ||
										(ignoreInfo.whoIgnoredName == parentApplication.lobby.mediaManager.userName));
	var isIgnoringLocalClient:Boolean = (((ignoreInfo.ignoredWhoAcctID != 0) && 
										(ignoreInfo.ignoredWhoAcctID == parentApplication.lobby.mediaManager.acctID)) ||
										(ignoreInfo.ignoredWhoName == parentApplication.lobby.mediaManager.userName));
	
	// if isLocalClientIgnoring,
	// update the __appWideSingleton.userInfoObj.ignores Object
	if (isLocalClientIgnoring)
	{
		// if the ignored user is not already ignored
		if (!isUserIgnored(ignoreInfo.ignoredWhoAcctID, ignoreInfo.ignoredWhoName))
		{
			if (isIgnoringAGuest)
			{
				//__appWideSingleton.userInfoObj.ignores.names["IGNORE_"+ignoreInfo.ignoredWhoName] = ignoreInfo;
				__appWideSingleton.userInfoObj.ignores["guest_"+ignoreInfo.ignoredWhoName] = ignoreInfo;
			} else {
				//__appWideSingleton.userInfoObj.ignores.acctids["IGNORE_"+ignoreInfo.ignoredWhoAcctID] = ignoreInfo;
				__appWideSingleton.userInfoObj.ignores["member_"+ignoreInfo.ignoredWhoAcctID] = ignoreInfo;
			}
			
			// TODO use AppWide_Singleton.appInfoObj.ignores
			LocalSOManager_Singleton.getInstance().setLocalSOProperty('ignores', __appWideSingleton.userInfoObj.ignores);
			
			// set the userList icons
			//userListPanel.ignoredUser(ignoreInfo);
			
			parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"You have BLOCKED "+ignoreInfo.ignoredWhoName+"!  They will not be able to view your cam, or see your chat."}));
		}
	} else {
		// ignored user is not the local client,
		// set the userList icons
		//userListPanel.ignoredUser(ignoreInfo);
	}
	
	// set the userList icons
	// (already done by the event handler?)
	userListPanel.ignoredUser(ignoreInfo);
	
	ignoreInfo = null;
	event = null;
}


public function unignoredUser(event:CustomEvent):void
{
	debugMsg("unignoredUser->  whoIgnoredName: "+event.eventObj.whoIgnoredName+"  whoIgnoredAcctID: "+event.eventObj.whoIgnoredAcctID+"  ignoredWhoName: "+event.eventObj.ignoredWhoName+"  ignoredWhoAcctID: "+event.eventObj.ignoredWhoAcctID);
	
	//if (event.eventObj.ignoredWhoName == mediaManager.userName)
	//{
	//	userListPanel.unignoredUser(event.eventObj);
	//} else {
	userListPanel.unignoredUser(event.eventObj);
	
	if (isUserIgnored(event.eventObj.ignoredWhoAcctID, event.eventObj.ignoredWhoName))
	{
		if (event.eventObj.ignoredWhoAcctID == 0)
		{
			//__appWideSingleton.userInfoObj.ignores.names["IGNORE_"+event.eventObj.ignoredWhoName] = null;
			__appWideSingleton.userInfoObj.ignores["guest_"+event.eventObj.ignoredWhoName] = null;
			delete __appWideSingleton.userInfoObj.ignores["guest_"+event.eventObj.ignoredWhoName];
		} else {
			//__appWideSingleton.userInfoObj.ignores.acctids["IGNORE_"+event.eventObj.ignoredWhoAcctID] = null;
			__appWideSingleton.userInfoObj.ignores["member_"+event.eventObj.ignoredWhoAcctID] = null;
			delete __appWideSingleton.userInfoObj.ignores["member_"+event.eventObj.ignoredWhoAcctID];
		}
		
		LocalSOManager_Singleton.getInstance().setLocalSOProperty('ignores', __appWideSingleton.userInfoObj.ignores);
		
		parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"You have UNBLOCKED "+event.eventObj.ignoredWhoName+"!  They will now be able to view your cam, and see your chat."}));
	}
	//}
	
	event = null;
}


public function isUserIgnored(acctID:Number, userName:String):Boolean
{
	var nodeName:String = (acctID == 0 ? "guest_"+userName : "member_"+acctID);
	var ignoreExists:Boolean = (__appWideSingleton.userInfoObj.ignores[nodeName] != undefined);
	var isIgnored:Boolean = false;
	
	//if (acctID == 0)
	//{
		//if (__appWideSingleton.userInfoObj.ignores.names["IGNORE_"+userName])
		if (ignoreExists)
		{
			isIgnored = true;
		}
	//} else {
	//	//if (__appWideSingleton.userInfoObj.ignores.acctids["IGNORE_"+acctID])
	//	if (__appWideSingleton.userInfoObj.ignores[nodeName])
	//	{
	//		isIgnored = true;
	//	}
	//}
	
	debugMsg("isUserIgnored->  acctID: "+acctID+"  userName: "+userName+"  nodeName: "+nodeName+"  isIgnored: "+isIgnored+(ignoreExists == false ? "" : "  ignores["+nodeName+"]: "+__appWideSingleton.userInfoObj.ignores[nodeName]));
	
	nodeName = null;
	//acctID = null;
	userName = null;
	
	return isIgnored;
}


public function receivePrivateMessage(event:CustomEvent):void
{
	debugMsg("receivePrivateMessage->  fromUserName: "+event.eventObj.fromUserName+"  toUserName: "+event.eventObj.toUserName+"  msg: "+event.eventObj.msg);
	
	if (openPopUps_AC.length)
	{
		for (var i:Object in openPopUps_AC)
		{
			trace("OPEN PM>  openPopUps_AC[i].id: "+openPopUps_AC[i].id+"  userID: "+event.eventObj.userID+"  fromUserID: "+event.eventObj.fromUserID+"  toUserID: "+event.eventObj.toUserID);
			if (openPopUps_AC[i].id == "pm_"+event.eventObj.userID)
			{
				trace("PM WINDOW ALREADY EXISTS!>>  openPopUps_AC[i].id: "+openPopUps_AC[i].id);
				//userListPanel.userCmdObj = event.eventObj;
				openPopUps_AC[i].receivePrivateMessage(event.cloneCustomEvent().eventObj);
				break;
			} else {
				// the PM window does not exist
				trace("EXISTING CURRENT POPUPS, BUT THIS PM WINDOW DOES NOT EXIST!>>    openPopUps_AC[i].id: "+openPopUps_AC[i].id);
				PopUpManager.createPopUp(parentApplication.lobby, PrivateMessage_PopUpTitleWindow, false);
				openPopUps_AC[openPopUps_AC.length - 1].receivePrivateMessage(event.eventObj);
				break;
			}
		}
		i = null;
	} else {
		// no current popUps
		trace("NO CURRENT POPUPS, AND THE PM WINDOW DOES NOT EXIST!");
		//userListPanel.userCmdObj = event.eventObj;
		PopUpManager.createPopUp(parentApplication.lobby, PrivateMessage_PopUpTitleWindow, false);
		//for (var y:Object in openPopUps_AC)
		//{
		//if (openPopUps_AC[y].cmdObj.toUserID == event.eventObj.toUserID)
		//{
		trace("PM WINDOW NOW EXISTS!");
		openPopUps_AC[openPopUps_AC.length - 1].receivePrivateMessage(event.cloneCustomEvent().eventObj);
		//}
		//}
		//y = null;
	}
	
	event = null;
}


public function receiveBannedUsers(event:CustomEvent):void
{
	debugMsg("receiveBannedUsers->  ");
	
	tmpObj = event.cloneCustomEvent().eventObj;
	
	PopUpManager.createPopUp(parentApplication.lobby, BanList_PopUpTitleWindow, false);
	
	event = null;
}


public function onGetBlockedUsersListResultHandler(event:CustomEvent):void
{
	debugMsg("onGetBlockedUsersListResultHandler->  eventObj: "+event.cloneCustomEvent().eventObj);
	
	var _tmpObj:Object = event.cloneCustomEvent().eventObj;
	
	for (var i:Object in _tmpObj)
	{
		if (!__appWideSingleton.userInfoObj.ignores[i])
			__appWideSingleton.userInfoObj.ignores[i] = _tmpObj[i];
		
		i = null;
	}
	
	//userListPanel.setBlockedUsers(_tmpObj);
	
	//PopUpManager.createPopUp(parentApplication.lobby, BlockList_PopUpTitleWindow, false);
	
	_tmpObj = null;
	event = null;
}


// TODO:
// check for (dis)graceful disconnection
public function close():void
{
	debugMsg("close->  "+new Date().toString());
	
	// stop the stats timer
	__appWideSingleton.statsTimer.stop();
	
	// close any open popups
	for (var x:int = 0; x < openPopUps_AC.length; ++x)
	{
		// TODO
		//openPopUps_AC[x].close();
		PopUpManager.removePopUp(openPopUps_AC[x]);
		openPopUps_AC.removeItemAt(x);
	}
	
	// close all docked cams
	for (x = 1; x <= __appWideSingleton.camSpotIDs_A.length; ++x)
	{
		parentApplication.lobby["camSpot"+x].clearCamSpot();
	}
	
	dockedUserIDs_AC.removeAll();
	
	// clean up the lobby
	mediaManager.close();  // stop publishing, nullify cam/mic objects
	userListPanel.close(); // clear/reset the list
	chatPanel.close();  // clear/reset the chat text
	
	// change the state to loginState
	parentApplication.currentState = "loginState";
	
	// hide the lobby
	//this.visible = false;
	
	// show the loginPanel
	//parentApplication.loginPanel.visible = true;
	
	// disable the blocks/bwcheck buttons
	parentApplication.applicationBar.applicationBar_blockList_Btn.enabled = false;
	parentApplication.applicationBar.bwChart.doBWCheck_Btn.enabled = false;
	
	// reset the saved ignores
	__appWideSingleton.userInfoObj.ignores = null;
	delete __appWideSingleton.userInfoObj.ignores;
	
	__appWideSingleton.userInfoObj.ignores = {};
	
	tmpObj = null;
	tmpStr = null;
}





private function debugMsg(str:String):void
{
	AppWideDebug_Singleton.getInstance().newDebugMessage(this.id, str);
	
	str = null;
}

