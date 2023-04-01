import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.LocalConnection;
import flash.system.System;

import mx.events.FlexEvent;

import events.CustomEvent;

import me.whohacked.app.AppWideDebug_Singleton;
import me.whohacked.app.AppWideEventDispatcher_Singleton;
import me.whohacked.app.AppWide_Singleton;
import me.whohacked.app.LocalSOManager_Singleton;


public var loginInfoObj:Object;
public var chatTextFormat:Object = {};


private var __chatMessageHistory_Vec:Vector.<String> = new Vector.<String>();
private var __maxNumLines:Number = 200;
private var __appWideSingleton:AppWide_Singleton;
private var __localSOManager:LocalSOManager_Singleton;



public function chatPanelCreationCompleteHandler(event:FlexEvent):void
{
	trace("|###| ChatPanel |###|>  LOADED");
	
	__appWideSingleton = AppWide_Singleton.getInstance();
	__localSOManager = LocalSOManager_Singleton.getInstance();
	
	loginInfoObj = __appWideSingleton.userInfoObj;
	
	if (!chatTextInput.chatTextInput_TI.hasEventListener("FlexEvent.ENTER"))
	{
		chatTextInput.chatTextInput_TI.addEventListener(FlexEvent.ENTER, sendMessageOnEnter, false,0,true);
	}
	
	if (!chatTextInput.sendMsgBtn.hasEventListener("FlexEvent.ENTER"))
	{
		chatTextInput.sendMsgBtn.addEventListener(FlexEvent.ENTER, sendMessageOnEnter, false,0,true);
	}
	
	if (!chatTextInput.sendMsgBtn.hasEventListener("MouseEvent.CLICK"))
	{
		chatTextInput.sendMsgBtn.addEventListener(MouseEvent.CLICK, sendMessageOnClick, false,0,true);
	}
	
	if (!parentApplication.loginPanel.nc.client.hasEventListener("receiveMessage"))
	{
		// listen for incoming chat messages
		parentApplication.loginPanel.nc.client.addEventListener("receiveMessage", receiveMessage, false,0,true);
	}
	
	if (!parentApplication.loginPanel.nc.client.hasEventListener("showAdminMessage"))
	{
		// listen for incoming admin messages
		parentApplication.loginPanel.nc.client.addEventListener("showAdminMessage", showAdminMessage, false,0,true);
	}
	
	fontControlBar.fontSize_NS.value = __localSOManager.getLocalSOProperty('fontSize');
	fontControlBar.fontColor_CP.selectedColor = __localSOManager.getLocalSOProperty('fontColor');
	fontControlBar.allFontSize_CB.selected = __localSOManager.getLocalSOProperty('isAllFontSizeChecked');
	
	chatTextFormat.fontSize = fontControlBar.fontSize_NS.value;
	chatTextFormat.fontColor = "#"+fixedInt(fontControlBar.fontColor_CP.selectedColor, '000000');
	
	chatTextFormat.isBold = __localSOManager.getLocalSOProperty('fontBold');
	chatTextFormat.isItalics = __localSOManager.getLocalSOProperty('fontItalics');
	chatTextFormat.isUnderline = __localSOManager.getLocalSOProperty('fontUnderline');
	
	event = null;
}


public function receiveMessage(event:CustomEvent):void
{
	//var _event:CustomEvent = event.clone();
	var msgObj:Object = event.eventObj;
	var userObj:Object = parentApplication.lobby.userListPanel.getUserObj(msgObj.userID);
	
	if (!parentApplication.lobby.isUserIgnored(msgObj.acctID, msgObj.nonDuplicateName) && !userObj.hasBlocked)
	{
		if ((msgObj.isAdminMessage) || (msgObj.isDebugMessage))
		{
			debugMsg("receiveMessage->  isAdminMessage: "+msgObj.isAdminMessage+"  isDebugMessage: "+msgObj.isDebugMessage);
			
			msgObj.isBold = true;
			msgObj.fontColor = '#FF0000';
			msgObj.fontSize = chatTextFormat.fontSize;
			//msgObj.fontSize = 12; // TEST
			
			if (msgObj.isAdminMessage)
				msgObj.userName = '* Admin';
			if (msgObj.isDebugMessage)
				msgObj.userName = '* DEBUG:  ' + ((msgObj.src != undefined) ? msgObj.src : '');
		}
		
		if (fontControlBar.allFontSize_CB.selected)
		{
			msgObj.fontSize = chatTextFormat.fontSize;
		}
		
		if (msgObj.isBold)
		{
			var bold:String = "<b>";
			var boldEnd:String = "</b>";
		} else {
			bold = "";
			boldEnd = "";
		}
		
		if (msgObj.isItalics)
		{
			var italics:String = "<i>";
			var italicsEnd:String = "</i>";
		} else {
			italics = "";
			italicsEnd = "";
		}
		
		if (msgObj.isUnderline)
		{
			var underline:String = "<u>";
			var underlineEnd:String = "</u>";
		} else {
			underline = "";
			underlineEnd = "";
		}
		
		if (msgObj.isAction)
		{
			showMsg("<font size='"+msgObj.fontSize+"' color='"+msgObj.fontColor+"' face='Verdana'><b>* "+msgObj.userName+"</b>  "+bold+italics+underline+ msgObj.msg +underlineEnd+italicsEnd+boldEnd+"</font>");
		} else {
			showMsg("<font size='"+msgObj.fontSize+"' color='"+msgObj.fontColor+"' face='Verdana'><b>"+msgObj.userName+"</b>:  "+bold+italics+underline+ msgObj.msg +underlineEnd+italicsEnd+boldEnd+"</font>");
		}
		
		bold = null;
		boldEnd = null;
		italics = null;
		italicsEnd = null;
		underline = null;
		underlineEnd = null;
	}
	
	//debugMsg("receiveMessage->  userName: "+userObj.userName+"  fontSize: "+msgObj.fontSize+"  fontColor: "+msgObj.fontColor+"  isBold: "+msgObj.isBold+"  msg: "+msgObj.msg);
	
	userObj = null;
	msgObj = null;
	event = null;
}


private function showMsg(htmlText:String):void
{
	// add the new line of text to the history
	__chatMessageHistory_Vec.push(htmlText + "<br />");
	
	var newHTMLText:String = '';
	
	// slice from the index 
	if (__chatMessageHistory_Vec.length >= __maxNumLines)
	{
		//__chatMessageHistory_A = __chatMessageHistory_A.slice((__chatMessageHistory_A.length - __maxNumLines), __chatMessageHistory_A.length);
		__chatMessageHistory_Vec = __chatMessageHistory_Vec.slice(((__chatMessageHistory_Vec.length - __maxNumLines) >= 0) ? (__chatMessageHistory_Vec.length - __maxNumLines) : 0, __chatMessageHistory_Vec.length);
		
		for (var i:int = 0; i < __chatMessageHistory_Vec.length; i++)
		{
			newHTMLText += __chatMessageHistory_Vec[i];
		}
		
		// set the new html text
		chatTextArea.chatTextArea_TA.htmlText = newHTMLText;
		
		//chatTextArea.chatTextArea_TA.htmlText = cleanChatHistory(chatTextArea.chatTextArea_TA.htmlText);
		//chatTextArea.chatTextArea_TA.validateNow();
	} else {
		chatTextArea.chatTextArea_TA.htmlText += htmlText + "<br />";
	}
	
	chatTextArea.chatTextArea_TA.validateNow();
	chatTextArea.chatTextArea_TA.verticalScrollPosition = chatTextArea.chatTextArea_TA.maxVerticalScrollPosition + 5;
	
	/*
	// force gc to prevent leaking
	try {
	new LocalConnection().connect('foo');
	new LocalConnection().connect('foo');
	} catch (e:*) {}
	*/
	
	//debugMsg("showMsg->  maxNumLines: " + __maxNumLines + "  chatMessageHistory_A.length: " + __chatMessageHistory_Vec.length /*+ "  privateMemory: " + System.privateMemory + "  totalMemory: " + System.totalMemory*/);
	
	newHTMLText = null;
	htmlText = null;
}


public function cleanChatHistory(htmlText:String):String
{
	var pattern:RegExp = /<P.*?<\/P>/gi; // "<P"
	var matchArray:Array = htmlText.match(pattern);
	var newChatArray:Array = matchArray.slice(1, matchArray.length);
	var pattern2:RegExp = /<\/P>,<P/gi;
	var arrString:String = newChatArray.toString().replace(pattern2, "<\/P><P");
	newChatArray = null;
	matchArray = null;
	pattern2 = null;
	pattern = null;
	htmlText = null;
	return arrString;
}


public function sendMessageOnEnter(event:FlexEvent):void
{
	sendMessageToServer();
	event = null;
}


public function sendMessageOnClick(event:MouseEvent):void
{
	sendMessageToServer();
	event = null;
}


public function sendMessageToServer():void
{
	// TODO:
	// allow the user to take a snapshot of their video
	// and save it as their account profile pic
	if (!chatTextInput.chatTextInput_TI.text.length) return;
	
	/*
	if (chatTextInput.chatTextInput_TI.text.split(" ")[0] == "/thumb")
	{
	AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("takeProfileSnapshot", false,false, {previewVideo:parentApplication.lobby.camSpot1.camSpot_V}));
	
	return;
	}
	
	// TEST
	if (chatTextInput.chatTextInput_TI.text.split(" ")[0] == "/test")
	{
	parentApplication.loginPanel.nc.call(chatTextInput.chatTextInput_TI.text.split(" ")[1], null, chatTextInput.chatTextInput_TI.text.split(" ")[2], chatTextInput.chatTextInput_TI.text.split(" ")[3], chatTextInput.chatTextInput_TI.text.split(" ")[4]);
	
	return;
	}
	
	// move to the admin panel...
	// if youve found this, have fun
	if (chatTextInput.chatTextInput_TI.text.split(" ")[0] == "/forcecamoff")
	{
	parentApplication.loginPanel.nc.call("mediaManager.userVideoOff", null, chatTextInput.chatTextInput_TI.text.split(" ")[1]);
	
	return;
	}
	*/
	
	chatTextFormat.fontColor = "#"+fixedInt(__localSOManager.getLocalSOProperty('fontColor'), '000000');
	chatTextFormat.fontSize = __localSOManager.getLocalSOProperty('fontSize');
	chatTextFormat.isBold = __localSOManager.getLocalSOProperty('fontBold');
	chatTextFormat.isItalics = __localSOManager.getLocalSOProperty('fontItalics');
	chatTextFormat.isUnderline = __localSOManager.getLocalSOProperty('fontUnderline');
	
	var msgObj:Object = chatTextFormat;
	msgObj.clientID = parentApplication.lobby.mediaManager.clientID;
	//msgObj.clientID = "4702111235313844591";
	msgObj.userID = loginInfoObj.userID;
	//msgObj.userID = "41";
	msgObj.acctID = loginInfoObj.acctID;
	msgObj.userName = loginInfoObj.userName;
	msgObj.roomName = loginInfoObj.roomName;
	msgObj.isPrivate = false;
	msgObj.isAdminMessage = true;
	
	if (parentApplication.lobby.userListPanel.userList_DG.selectedItem)
	{
		msgObj.selectedUserID = parentApplication.lobby.userListPanel.userList_DG.selectedItem.userID;
	}
	
	msgObj.msg = chatTextInput.chatTextInput_TI.text.toString();
	
	parentApplication.loginPanel.nc.call("chatManager.sendMessage", null, msgObj);
	
	debugMsg("sendMessageToServer->  userName: "+loginInfoObj.userName+"  fontColor: "+msgObj.fontColor+"  fontSize: "+msgObj.fontSize+"  isBold: "+msgObj.isBold+"  msg: "+msgObj.msg);
	
	chatTextInput.chatTextInput_TI.text = "";
	
	msgObj = null;
}


public function showAdminMessage(event:CustomEvent):void
{
	var tmpObj:Object = event.eventObj;
	trace("|###| ChatPanel.showAdminMessage |###|>  msg: "+tmpObj.msg);
	
	parentApplication.loginPanel.nc.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, isDebugMessage:false, msg:tmpObj.msg}));
	
	//showMsg("<font size='16' face='Verdana' color='#FF0000'><b>* Admin:  "+event.eventObj.msg+"</b></font>");
	/*
	chatTextArea.chatTextArea_TA.htmlText += "<font size='12' face='Verdana' color='#FF0000'><b>* Admin:  "+event.eventObj.msg+"</b></font>"+"\n";
	if(chatTextArea.chatTextArea_TA.mx_internal::getTextField().numLines >= 50)
	{
	chatTextArea.chatTextArea_TA.htmlText = cleanChatHistory(chatTextArea.chatTextArea_TA.htmlText);
	//chatTextArea.chatTextArea_TA.validateNow();
	}
	chatTextArea.chatTextArea_TA.validateNow();
	chatTextArea.chatTextArea_TA.verticalScrollPosition = chatTextArea.chatTextArea_TA.maxVerticalScrollPosition;
	*/
	
	tmpObj = null;
	event = null;
}


public function userEnterLeave(userName:String, inOut:String):void
{
	trace("|###| ChatPanel.userEnterLeave |###|>  userName: "+userName+"  inOut: "+inOut);
	
	showMsg("<font size='"+chatTextFormat.fontSize+"' face='Verdana' color='#19B819'><b>* "+userName+" "+inOut+" the room</b></font>");
	
	/*
	chatTextArea.chatTextArea_TA.htmlText += "<font size='14' face='Verdana' color='#19B819'><b>* "+userName+" "+inOut+" the room</b></font>"+"\n";
	if(chatTextArea.chatTextArea_TA.mx_internal::getTextField().numLines >= 50)
	{
	chatTextArea.chatTextArea_TA.htmlText = cleanChatHistory(chatTextArea.chatTextArea_TA.htmlText);
	//chatTextArea.chatTextArea_TA.validateNow();
	}
	chatTextArea.chatTextArea_TA.validateNow();
	chatTextArea.chatTextArea_TA.verticalScrollPosition = chatTextArea.chatTextArea_TA.maxVerticalScrollPosition;
	*/
	userName = null;
	inOut = null;
}


public function showIntroText():void
{
	//chatTextArea.chatTextArea_TA.htmlText = null;
	chatTextArea.chatTextArea_TA.text = "";
	
	showMsg("<font size='12' face='Verdana' color='#FF0000'><b>* ***HOW TO USE***</b></font>");
	showMsg("<font size='12' face='Verdana' color='#393939'><b>* DOUBLE CLICK A USER IN THE LIST TO VIEW THEIR CAM</b></font>");
	showMsg("<font size='12' face='Verdana' color='#393939'><b>* CLICK THE ARROW BUTTON TO SWITCH THE CAM BETWEEN THE SMALL/MAIN CAMS</b></font>");
	showMsg("<font size='12' face='Verdana' color='#393939'><b>* DRAG AND DROP THE CAMS TO ANY SPOT YOU WANT</b></font>");
	showMsg("<font size='12' face='Verdana' color='#FF0000'><b>* TRY LOW QUALITY, OR CLOSE SOME CAMS IF YOU LAG.</b></font>"+"\n");
	//showMsg("<font size='11' face='Verdana' color='#FF0000'><b>* WANT TO TRY THE LATEST FEATURES? <u><a href='https://www.toketub.tv/beta' target='_self'><font color='#0000FF'>USE THE BETA!</font></a></u></b></font>"+"\n");
	//showMsg("<font size='12' face='Verdana' color='#FF0000'><b>* </b></font>"+"\n");
}


public function close():void
{
	camControlBar.close();
	
	__chatMessageHistory_Vec.slice(0, __chatMessageHistory_Vec.length - 1);
	
	//chatTextArea.chatTextArea_TA.htmlText = null;
	chatTextArea.chatTextArea_TA.text = null;
}





private function fixedInt(value:uint, mask:String):String
{
	return String(mask + value.toString(16)).substr(-mask.length).toUpperCase();
}


private function debugMsg(str:String):void
{
	AppWideDebug_Singleton.getInstance().newDebugMessage(this.id, str);
}

