/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
import mx.events.FlexEvent;

import events.CustomEvent;



protected function camControlBarCreationCompleteHandler(event:FlexEvent):void
{
	trace("|###| CamControlBar |###|>  LOADED");
	event = null;
}


protected function camOnOffBtn_clickHandler(event:MouseEvent):void
{
	switch (camOnOffBtn.label)
	{
		case "TURN YOUR CAM ON":
			camOnOffBtn.setStyle("color","#FF0000");
			camOnOffBtn.label = "TURN YOUR CAM OFF";
			for (var i:Object in parentApplication.lobby.userListPanel.userList_DP)
			{
				if (parentApplication.lobby.userListPanel.userList_DP[i].userID == parentApplication.lobby.mediaManager.userID)
				{
					parentApplication.lobby.userListPanel.userList_DP[i].isUsersVideoOn = true;
				}
			}
			parentApplication.lobby.mediaManager.startVideo(parentApplication.lobby.mediaManager.userID);
			parentApplication.lobby.userListPanel.userList_DG.invalidateList();
			
			/*
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.htmlText += "<font color='#FF0000' size='16'><b>* Admin:  YOUR VIDEO IS NOW ON!</b></font>";
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.validateNow();
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.verticalScrollPosition = parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.maxVerticalScrollPosition;
			*/
			
			parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"YOUR VIDEO IS NOW ON!"}));
			
			i = null;
		break;
		case "TURN YOUR CAM OFF":
			camOnOffBtn.setStyle("color","#FFFFFF");
			camOnOffBtn.label = "TURN YOUR CAM ON";
			for (i in parentApplication.lobby.userListPanel.userList_DP)
			{
				if (parentApplication.lobby.userListPanel.userList_DP[i].userID == parentApplication.lobby.mediaManager.userID)
				{
					parentApplication.lobby.userListPanel.userList_DP[i].isUsersVideoOn = false;
				}
			}
			parentApplication.lobby.mediaManager.stopVideo(parentApplication.lobby.mediaManager.userID);
			parentApplication.lobby.userListPanel.userList_DG.invalidateList();
			
			/*
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.htmlText += "<font color='#FF0000' size='16'><b>* Admin:  YOUR VIDEO IS NOW OFF!</b></font>";
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.validateNow();
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.verticalScrollPosition = parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.maxVerticalScrollPosition;
			*/
			
			parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"YOUR VIDEO IS NOW OFF!"}));
			
			i = null;
		break;
	}
	event = null;
}


protected function audioOnOffBtn_clickHandler(event:MouseEvent):void
{
	switch (audioOnOffBtn.label)
	{
		case "TURN YOUR AUDIO ON":
			audioOnOffBtn.setStyle("color","#FF0000");
			audioOnOffBtn.label = "TURN YOUR AUDIO OFF";
			for (var i:Object in parentApplication.lobby.userListPanel.userList_DP)
			{
				if (parentApplication.lobby.userListPanel.userList_DP[i].userID == parentApplication.lobby.mediaManager.userID)
				{
					parentApplication.lobby.userListPanel.userList_DP[i].isUsersAudioOn = true;
				}
			}
			parentApplication.lobby.mediaManager.startAudio(parentApplication.lobby.mediaManager.userID);
			parentApplication.lobby.userListPanel.userList_DG.invalidateList();
			
			/*
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.htmlText += "<font color='#FF0000' size='16'><b>* Admin:  YOUR AUDIO IS NOW ON!</b></font>";
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.validateNow();
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.verticalScrollPosition = parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.maxVerticalScrollPosition;
			*/
			
			parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"YOUR AUDIO IS NOW ON!"}));
			
			i = null;
		break;
		case "TURN YOUR AUDIO OFF":
			audioOnOffBtn.setStyle("color","#FFFFFF");
			audioOnOffBtn.label = "TURN YOUR AUDIO ON";
			for (i in parentApplication.lobby.userListPanel.userList_DP)
			{
				if (parentApplication.lobby.userListPanel.userList_DP[i].userID == parentApplication.lobby.mediaManager.userID)
				{
					parentApplication.lobby.userListPanel.userList_DP[i].isUsersAudioOn = false;
				}
			}
			parentApplication.lobby.mediaManager.stopAudio(parentApplication.lobby.mediaManager.userID);
			parentApplication.lobby.userListPanel.userList_DG.invalidateList();
			
			/*
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.htmlText += "<font color='#FF0000' size='16'><b>* Admin:  YOUR AUDIO IS NOW OFF!</b></font>";
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.validateNow();
			parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.verticalScrollPosition = parentApplication.lobby.chatPanel.chatTextArea.chatTextArea_TA.maxVerticalScrollPosition;
			*/
			
			parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"YOUR AUDIO IS NOW OFF!"}));
			
			i = null;
		break;
	}
	event = null;
}


public function close():void
{
	if (audioOnOffBtn.label=="TURN YOUR AUDIO OFF")
	{
		audioOnOffBtn.setStyle("color","#FFFFFF");
		audioOnOffBtn.label = "TURN YOUR AUDIO ON";
		/*for (var i:Object in parentApplication.lobby.userListPanel.userList_DP)
		{
			if (parentApplication.lobby.userListPanel.userList_DP[i].userID == parentApplication.lobby.mediaManager.userID)
			{
				parentApplication.lobby.userListPanel.userList_DP[i].isUsersAudioOn = false;
			}
		}
		parentApplication.lobby.mediaManager.stopAudio(parentApplication.lobby.mediaManager.userID);
		parentApplication.lobby.userListPanel.userList_DG.invalidateList();
		i = null;*/
	}
	if (camOnOffBtn.label=="TURN YOUR CAM OFF")
	{
		camOnOffBtn.setStyle("color","#FFFFFF");
		camOnOffBtn.label = "TURN YOUR CAM ON";
		/*for (i in parentApplication.lobby.userListPanel.userList_DP)
		{
			if (parentApplication.lobby.userListPanel.userList_DP[i].userID == parentApplication.lobby.mediaManager.userID)
			{
				parentApplication.lobby.userListPanel.userList_DP[i].isUsersVideoOn = false;
			}
		}
		parentApplication.lobby.mediaManager.stopVideo(parentApplication.lobby.mediaManager.userID);
		parentApplication.lobby.userListPanel.userList_DG.invalidateList();
		i = null;*/
	}
}
