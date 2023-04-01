import flash.events.Event;
import flash.events.TextEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;

import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.utils.StringUtil;

import spark.components.RadioButtonGroup;

import components.popups.Reconnect_PopUpTitleWindow;

import events.CustomEvent;

import me.whohacked.app.AppWideDebug_Singleton;
import me.whohacked.app.AppWideEventDispatcher_Singleton;
import me.whohacked.app.AppWide_Singleton;
import me.whohacked.app.IconManager_Singleton;
import me.whohacked.app.LocalSOManager_Singleton;

import scripts.net.NetConnectionManager;



public var nc:NetConnectionManager;
public var loginInfoObj:Object;


//[Bindable]
//public var selectedConnectionProtocol_RBG:RadioButtonGroup = new RadioButtonGroup();
//[Bindable] public var selectedVideoCodec_RBG:RadioButtonGroup = new RadioButtonGroup();
//[Bindable] public var selectedAudioCodec_RBG:RadioButtonGroup = new RadioButtonGroup();


[Bindable]
private var __iconManager:IconManager_Singleton;
private var __appWideSingleton:AppWide_Singleton;



private function loginPanel_initializeHandler(event:FlexEvent):void
{
	__appWideSingleton = AppWide_Singleton.getInstance();
	__iconManager = IconManager_Singleton.getInstance();
	
	loginInfoObj = __appWideSingleton.userInfoObj;
	
	nc = __appWideSingleton.localNetConnection;
	
	AppWideEventDispatcher_Singleton.getInstance().addEventListener('onApplicationComplete', onApplicationCompleteHandler, false,0,true);
	
	event = null;
}


private function loginPanel_creationCompleteHandler(event:FlexEvent):void
{
	trace("|###| LoginPanel |###|>  LOADED");
	
	event = null;
}


private function onApplicationCompleteHandler(event:Event):void
{
	debugMsg("onApplicationCompleteHandler->  ");
	
	var localSOManager:LocalSOManager_Singleton = LocalSOManager_Singleton.getInstance();
	
	// get saved info from the local SO
	if (localSOManager.getLocalSOProperty('login'))
	{
		userName_TI.text = localSOManager.getLocalSOProperty('login');
	}
	
	if (localSOManager.getLocalSOProperty('pass'))
	{
		password_TI.text = localSOManager.getLocalSOProperty('pass');
	}
	/*
	if (localSOManager.getLocalSOProperty('lastRoomName'))
	{
		roomName_TI.text = localSOManager.getLocalSOProperty('lastRoomName');
	}
	*/
	if (__appWideSingleton.appInfoObj['showBWChart'])
	{
		parentApplication.applicationBar.bwChart.showBWChart = __appWideSingleton.appInfoObj['showBWChart'];
	}
	
	// TODO:
	// optimize, remove double flashVars check
	if (__appWideSingleton.flashVars)
	{
		if ((__appWideSingleton.flashVars.roomName) &&
			(__appWideSingleton.flashVars.roomName.length))
		{
			roomName_TI.text = __appWideSingleton.flashVars.roomName;
			//Alert.show("flashVars.roomName:\t" + __appWideSingleton.flashVars.roomName+"\n");
		} else {
			//Alert.show("roomName does not exist!\n\nflashVars.roomName:\t" + __appWideSingleton.flashVars.roomName+"\n");
		}
		/**/
		if ((__appWideSingleton.flashVars.url) &&
			(__appWideSingleton.flashVars.url.length))
		{
			//parentApplication.applicationBar.applicationBar_titleText_L.text = "BongTVLive.com";
			registerURL_T.htmlText = "<a href='event:https://whohacked.me/register' target='new'>CREATE/EDIT YOUR ACCOUNT @ https://whohacked.me/register</a>";
			
			/*
			var urlArr:Array = __appWideSingleton.flashVars.url.toString().split("/");
			var url:String = urlArr[0]+"//"+urlArr[2];
			
			if (url.toLowerCase().indexOf("bongtvlive.com") != -1)
			{
				
				if (!roomName_TI.text.length)
					roomName_TI.text = "lobby";
				
				registerURL_T.htmlText = "<a href='event:"+url+"/register' target='_blank'>CREATE/EDIT YOUR ACCOUNT @ "+url+"/register</a>";
			} else {
				registerURL_T.htmlText = "";
			}*/
		}
	} else {
		//Alert.show("flashVars does not exist!\n\nflashVars:\t" + __appWideSingleton.flashVars+"\n");
	}
	
	// select the saved defaultQuality RadioButton
	var defaultQuality:String = localSOManager.getLocalSOProperty('defaultQuality');
	if (this[defaultQuality+"Quality_RB"])
	{
		this[defaultQuality+"Quality_RB"].selected = true;
	}
	
	savePassword_CB.selected = localSOManager.getLocalSOProperty('isSavePasswordChecked');
	
	autoFillCamsOnJoin_CB.selected = localSOManager.getLocalSOProperty('isAutoFillCamsChecked');
	
	allVideoOffOnJoin_CB.selected = localSOManager.getLocalSOProperty('isAllCamsOffChecked');
	allAudioOffOnJoin_CB.selected = localSOManager.getLocalSOProperty('isAllAudioOffChecked');
	
	useOthersQuality_CB.selected = localSOManager.getLocalSOProperty('isUseOthersQualityChecked');
	
	voiceChatEnabled_CB.selected = localSOManager.getLocalSOProperty('isVoiceChatEnabled'); // TODO
	
	if (localSOManager.getLocalSOProperty('isRoomHostOnMainChecked') != undefined)
	{
		roomHostOnMain_CB.selected = localSOManager.getLocalSOProperty('isRoomHostOnMainChecked');
		roomHostAutoUnmute_CB.selected = localSOManager.getLocalSOProperty('isUnmuteRoomHostChecked');
	} else {
		roomHostOnMain_CB.selected = true;
		roomHostAutoUnmute_CB.selected = true;
	}
	
	// TEMP
	// force chosen codec to Sorenson
	//__appWideSingleton.setAppInfo('selectedVideoCodec', 'sorenson');
	
	// TEMP
	//if (selectedConnectionProtocol == "rtmps")
	//	__appWideSingleton.setAppInfo('selectedConnectionProtocol', 'rtmp');
	
	/**/
	//TODO
	// set the saved video codec
	var selectedVideoCodec:String = localSOManager.getLocalSOProperty('selectedVideoCodec').toString().toLocaleUpperCase();
	if ((selectedVideoCodec.length) && 
		(this["selectedVideoCodec_"+selectedVideoCodec+"_RB"]))
		this["selectedVideoCodec_"+selectedVideoCodec+"_RB"].selected = true;
	
	// set the saved audio codec
	var selectedAudioCodec:String = localSOManager.getLocalSOProperty('selectedAudioCodec').toString().toLocaleUpperCase();
	if ((selectedAudioCodec.length) && 
		(this["selectedAudioCodec_"+selectedAudioCodec+"_RB"]))
		this["selectedAudioCodec_"+selectedAudioCodec+"_RB"].selected = true;
	
	// set the saved connection protocol
	var selectedConnectionProtocol:String = localSOManager.getLocalSOProperty('selectedConnectionProtocol').toString().toLocaleUpperCase();
	if ((selectedConnectionProtocol.length) && 
		(this["selectedConnectionProtocol_"+selectedConnectionProtocol+"_RB"]))
		this["selectedConnectionProtocol_"+selectedConnectionProtocol+"_RB"].selected = true;
	
	// TODO:
	// set auto-reconnect and auto-adjust for bw
	
	
	versionInfo_L.text = "v"+__appWideSingleton.appInfoObj.version;
	
	parentApplication.lobby.x = 0;
	parentApplication.lobby.y = 0;
	this.horizontalCenter = 0;
	
	selectedConnectionProtocol = null;
	selectedAudioCodec = null;
	selectedVideoCodec = null;
	defaultQuality = null;
	localSOManager = null;
	event = null;
}


/*
private function clearSOBtn_clickHandler(event:MouseEvent):void
{
	__appWideSingleton.localSOManager.localSO.clear();
	__appWideSingleton.localSOManager.localSO.flush();
	clearSOBtn.setStyle("color",0xFFFFFF);
	clearSOBtn.label = "NOW REFRESH!";
	loginBtn.enabled = false;
	event = null;
}
*/


private function loginBtn_clickHandler(event:*):void
{
	var localSOManager:LocalSOManager_Singleton = LocalSOManager_Singleton.getInstance();
	
	/*if (localSOManager.getLocalSOProperty('isBanned'))
	{
		// if the banTime has expired, then set isBanned to false
		//__appWideSingleton.setAppInfo('isBanned', false);
		
		setLoginStatusInfo("You have been banned!");
		
		Alert.show("You have been banned!"+"\n"+"\n"+
					"If you have been unbanned, clear your browser cache and refresh the page."+"\n"+"\n"+"\n"+
					"isBanned: "+localSOManager.getLocalSOProperty('isBanned'));
	} else {*/
		switch (loginBtn.label)
		{
			case "Login":
				// TODO
				// auto block emails without passwords
				if ((isValidEmail(userName_TI.text)) && 
					(!password_TI.text.length))
				{
					setLoginStatusInfo("You can not use an email for a guest name.");
					
					return;
				}
				
				loginBtn.label = "Cancel";
				
				setLoginStatusInfo("Logging into the chat...");
				
				// disable the components until the connection is closed
				userName_TI.enabled = false;
				password_TI.enabled = false;
				roomName_TI.enabled = false;
				lowQuality_RB.enabled = false;
				mediumQuality_RB.enabled = false;
				highQuality_RB.enabled = false;
				savePassword_CB.enabled = false;
				roomHostOnMain_CB.enabled = false;
				roomHostAutoUnmute_CB.enabled = false;
				autoFillCamsOnJoin_CB.enabled = false;
				allVideoOffOnJoin_CB.enabled = false;
				allAudioOffOnJoin_CB.enabled = false;
				useOthersQuality_CB.enabled = false;
				voiceChatEnabled_CB.enabled = false;
				selectedVideoCodec_RBG.enabled = false;
				selectedAudioCodec_RBG.enabled = false;
				selectedConnectionProtocol_RBG.enabled = false;
				
				// trim whitespaces from the beginning/end of the user/roomname
				userName_TI.text = parseOutHTML(userName_TI.text);
				userName_TI.text = StringUtil.trim(userName_TI.text);
				// force roomname to lowercase
				roomName_TI.text = parseOutHTML(roomName_TI.text.toLocaleLowerCase());
				roomName_TI.text = StringUtil.trim(roomName_TI.text);
				
				// save the info to the application
				if (userName_TI.text.length)
					__appWideSingleton.setAppInfo('login', userName_TI.text);
				if ((savePassword_CB.selected) && (password_TI.text.length))
					__appWideSingleton.setAppInfo('pass', password_TI.text);
				if (roomName_TI.text.length)
					__appWideSingleton.setAppInfo('lastRoomName', roomName_TI.text);
				else
					__appWideSingleton.setAppInfo('lastRoomName', 'lobby');
				
				__appWideSingleton.setAppInfo('isSavePasswordChecked', savePassword_CB.selected);
				__appWideSingleton.setAppInfo('isVoiceChatEnabled', voiceChatEnabled_CB.selected);
				__appWideSingleton.setAppInfo('isRoomHostOnMainChecked', roomHostOnMain_CB.selected);
				__appWideSingleton.setAppInfo('isUnmuteRoomHostChecked', roomHostAutoUnmute_CB.selected);
				
				__appWideSingleton.setAppInfo('isAutoFillCamsChecked', autoFillCamsOnJoin_CB.selected);
				__appWideSingleton.setAppInfo('isAllCamsOffChecked', allVideoOffOnJoin_CB.selected);
				__appWideSingleton.setAppInfo('isAllAudioOffChecked', allAudioOffOnJoin_CB.selected);
				__appWideSingleton.setAppInfo('isUseOthersQualityChecked', useOthersQuality_CB.selected);
				
				__appWideSingleton.setAppInfo('selectedVideoCodec', selectedVideoCodec_RBG.selectedValue.toString().toLocaleLowerCase());
				__appWideSingleton.setAppInfo('selectedAudioCodec', selectedAudioCodec_RBG.selectedValue.toString().toLocaleLowerCase());
				__appWideSingleton.setAppInfo('selectedConnectionProtocol', selectedConnectionProtocol_RBG.selectedValue.toString().toLocaleLowerCase());
				
				login(userName_TI.text, password_TI.text, roomName_TI.text);
			break;
			case "Cancel":
				loginBtn.label = "Login";
				disconnect();
			break;
		}
	//}// end if banned
	
	localSOManager = null;
	event = null;
}


public function login(userName:String, password:String, roomName:String):void
{
	var params:Object = new Object();
	params.userName = (userName.length ? StringUtil.trim(parseOutHTML(userName)) : "Guest");
	params.password = password;
	
	params.defaultQuality = __appWideSingleton.appInfoObj.defaultQuality;
	params.version = __appWideSingleton.appInfoObj.version;
	
	params.previousClientID = __appWideSingleton.previousClientIDs_A.length ? __appWideSingleton.previousClientIDs_A.pop().toString() : '';
	
	if (roomName_TI.text.length)
		params.roomName = StringUtil.trim(parseOutHTML(roomName));
	else
		params.roomName = 'lobby';
	
	// check if it is not connected already
	if (!nc.connected)
	{
		// if not, then connect
		connect(params);
	} else {
		// if so, then close and reconnect
		nc.close();
		login(userName, password, roomName);
	}
	
	params = null;
	roomName = null;
	password = null;
	userName = null;
}


public function connect(_params:Object):void
{
	debugMsg("connect->  params.userName: "+_params.userName);
	
	var ncURI:String = "";
	
	if (__appWideSingleton.appInfoObj.selectedConnectionProtocol)
	{
		switch (__appWideSingleton.appInfoObj.selectedConnectionProtocol)
		{
			case 'rtmp':
			{
				ncURI += 'rtmpe';
				break;
			}
			case 'rtmps':
			{
				ncURI += 'rtmps';
				break;
			}
			case 'rtmpt':
			{
				ncURI += 'rtmpte';
				break;
			}
			case 'rtmfp':
			{
				ncURI += 'rtmfp';
				break;
			}
			default:
			{
				ncURI += 'rtmpe';
				break;
			}
		}
	} else {
		ncURI += "rtmpe";
	}
	
	ncURI += "://media.whohacked.me"+((__appWideSingleton.appInfoObj.selectedConnectionProtocol=='rtmps' ? ":4430":"") || 
										(__appWideSingleton.appInfoObj.selectedConnectionProtocol=='rtmpt' ? ":80":""))+
										"/tub2010_server/"+_params.roomName.toLowerCase();
	/*ncURI += "://192.168.10.104/tub2010_server/"+_params.roomName.toLowerCase();*/
	//ncURI += "://10.0.0.104/tub2010_server/"+_params.roomName.toLowerCase();/**/
	//ncURI += "://media.whohacked.me/tub2010_server/"+_params.roomName.toLowerCase();
	
	// connect to the server (SSL)
	if (__appWideSingleton.appInfoObj.selectedConnectionProtocol == 'rtmps')
		nc.proxyType = 'best';
	else
		nc.proxyType = 'none';
	
	nc.createNetConnection(ncURI, _params);
	//nc.createNetConnection("rtmfp://209.95.38.230/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmps://media.whohacked.me/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmpe://media.whohacked.me/tub2010_server_test/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmpe://media.whohacked.me/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmpe://209.95.38.230/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmfp://209.95.38.230/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmpe://10.0.0.111/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	//nc.createNetConnection("rtmpe://192.168.10.104/tub2010_server/"+_params.roomName.toLowerCase(), _params);
	
	// try not to have duplicate listeners
	if (!nc.hasEventListener("onConnect"))
	{
		nc.addEventListener("onConnect", onNCConnect, false,0,true);
	}
	if (!nc.hasEventListener("onFailed"))
	{
		nc.addEventListener("onFailed", onNCFailed, false,0,true);
	}
	if (!nc.hasEventListener("onRejected"))
	{
		nc.addEventListener("onRejected", onNCRejected, false,0,true);
	}
	if (!nc.hasEventListener("onClosed"))
	{
		nc.addEventListener("onClosed", onNCClosed, false,0,true);
	}
	if (!nc.client.hasEventListener("loginFailed"))
	{
		nc.client.addEventListener("loginFailed", loginFailed, false,0,true);
	}
	if (!nc.client.hasEventListener("kicked"))
	{
		nc.client.addEventListener("kicked", onKicked, false,0,true);
	}
	if (!nc.client.hasEventListener("banned"))
	{
		nc.client.addEventListener("banned", onBanned, false,0,true);
	}
	
	ncURI = null;
	_params = null;
}


public function disconnect():void
{
	// close the NetConnection
	if (nc.connected) nc.close();
	
	// close the lobby components
	parentApplication.lobby.close();
	
	// re-enable the components
	userName_TI.enabled = true;
	password_TI.enabled = true;
	roomName_TI.enabled = true;
	lowQuality_RB.enabled = true;
	mediumQuality_RB.enabled = true;
	highQuality_RB.enabled = true;
	savePassword_CB.enabled = true;
	roomHostOnMain_CB.enabled = true;
	roomHostAutoUnmute_CB.enabled = true;
	autoFillCamsOnJoin_CB.enabled = true;
	allVideoOffOnJoin_CB.enabled = true;
	allAudioOffOnJoin_CB.enabled = true;
	useOthersQuality_CB.enabled = true;
	//voiceChatEnabled_CB.enabled = true;
	selectedVideoCodec_RBG.enabled = true;
	selectedAudioCodec_RBG.enabled = true;
	selectedConnectionProtocol_RBG.enabled = true;
	
	parentApplication.applicationBar.bwChart.doBWCheck_Btn.enabled = false;
	
	loginBtn.label = "Login";
}


private function onNCConnect(event:CustomEvent):void
{
	//trace("|###| LoginPanel.onNCConnect |###|>  CONNECTION SUCCESSFULL");
	debugMsg("onNCConnect->  CONNECTION SUCCESSFULL");
	
	setLoginStatusInfo("Connected! Loading the chat...");
	
	parentApplication.applicationBar.bwChart.doBWCheck_Btn.enabled = true;
	
	event = null;
}


private function onNCFailed(event:CustomEvent):void
{
	//trace("|###| LoginPanel.onNCFailed |###|>  CONNECTION FAILED");
	debugMsg("onNCFailed->  CONNECTION FAILED");
	
	setLoginStatusInfo("Connection failed! Please login again.");
	
	disconnect();
	
	// TEST: auto-reconnect
	if (__appWideSingleton.loggedOut==true)
	{
		// disconnected before logout, reconnect
		PopUpManager.createPopUp(this, Reconnect_PopUpTitleWindow, true);
	}
	
	event = null;
}


private function onNCRejected(event:CustomEvent):void
{
	var errObj:Object = event.eventObj;
	
	//trace("|###| LoginPanel.onNCRejected |###|>  CONNECTION REJECTED");
	debugMsg("onNCRejected->  CONNECTION REJECTED  errObj: "+errObj+"  error: "+errObj.code);
	
	setLoginStatusInfo("Connection rejected!  Error: " + (errObj.application ? errObj.application.code : errObj.code));
	
	disconnect();
	
	// TEST: auto-reconnect
	if (__appWideSingleton.loggedOut==true)
	{
		// disconnected before logout, reconnect
		PopUpManager.createPopUp(this, Reconnect_PopUpTitleWindow, true);
	}
	
	errObj = null;
	event = null;
}


private function onNCClosed(event:CustomEvent):void
{
	//trace("|###| LoginPanel.onNCClosed |###|>  CONNECTION CLOSED");
	debugMsg("onNCClosed->  CONNECTION CLOSED");
	
	disconnect();
	
	setLoginStatusInfo("Connection closed! Please login again.");
	//Alert.show("Connection lost!"+"\n"+"Please login again."+"\n"+"\n"+"If this problem persists, try a lower quality and make sure there is not a problem with your internet connection.");
	
	// TEST: auto-reconnect
	// disconnected before logout, reconnect
	if (__appWideSingleton.loggedOut==false)
	{
		PopUpManager.createPopUp(this, Reconnect_PopUpTitleWindow, true);
	}
	
	event = null;
}


private function loginFailed(event:CustomEvent):void
{
	debugMsg("loginFailed->  LOGIN FAILED  reason: "+event.eventObj.reason);
	
	disconnect();
	
	switch (event.eventObj.reason)
	{
		case "failed":
			setLoginStatusInfo("Login failed! Check your username/password.");
			//Alert.show("Login failed!"+"\n"+"Check your username/password."+"\n"+"\n"+"Make sure you have registered an account.");
		break;
		case "version":
			setLoginStatusInfo("Incompatible version! Refresh to update.");
			//Alert.show("Incompatible version! Refresh the page to update (CTRL+R in Firefox).\n\nOnly clear your cache if you get errors or if it will not get the new version."+"\n"+"\n");
			Alert.show("Your version is not up to date and is not compatible!"+"\n"+"\n"+"NOTE: Only clear your browser data/cache from your browser settings, if refreshing does not work the first few times!"+"\n"+"\n");
		break;
		case "guests":
			setLoginStatusInfo("Guest access has been disabled. Try again later!");
			//Alert.show("An admin has temporarily disabled guest access."+"\n"+"\n"+"Try again later, or create an account!"+"\n"+"\n");
		break;
		case "toomanyconnections":
			setLoginStatusInfo("Too many connections from your IP!");
			//Alert.show("\n"+"\n"+"\n");
		break;
	}
	event = null;
}


private function onKicked(event:CustomEvent):void
{
	__appWideSingleton.loggedOut = true;
	
	setLoginStatusInfo("You have been kicked!");
	
	disconnect();
	
	Alert.show("You have been kicked!"+"\n"+"\n"+"\n"+
				"Kicked by:  "+event.eventObj.adminname+"\n"+"\n"+
				"Reason:  "+event.eventObj.reason+"\n"+"\n");
	/*
	try
	{
		var urlRequest:URLRequest = new URLRequest("javascript:self.close();");
		navigateToURL(urlRequest, "_self");
	}
	catch(e:Error)
	{
		//exception here... i.e. if it is not allowed to call JavaScript from flash, then it will come here...
	}
	*/
	event = null;
}


private function onBanned(event:CustomEvent):void
{
	__appWideSingleton.loggedOut = true;
	
	setLoginStatusInfo("You have been banned!");
	
	disconnect();
	
	Alert.show("You have been banned!"+"\n"+"\n"+"\n"+
				"Banned by:  "+event.eventObj.adminname+"\n"+"\n"+
				"Date:  "+event.eventObj.banDate+"\n"+"\n"+
				"Reason:  "+event.eventObj.reason+"\n"+"\n");
	
	__appWideSingleton.setAppInfo('isBanned', true);
	
	event = null;
}


private function setLoginStatusInfo(msg:String):void
{
	loginStatusInfo_T.text = msg;
	msg = null;
}


private function registerURL_linkHandler(event:TextEvent):void
{
	debugMsg("registerURL_linkHandler->  eventText: "+event.text);
	
	navigateToURL(new URLRequest(event.text), '_new');
	
	event.stopPropagation();
	
	event = null;
}


private function quality_RB_clickHandler(quality:String):void
{
	__appWideSingleton.setAppInfo('defaultQuality', quality);
	
	quality = null;
}




private function selectedVideoCodec_RBG_changeHandler(event:Event):void
{
	var codec:String = selectedVideoCodec_RBG.selectedValue.toString().toLowerCase();
	
	__appWideSingleton.setAppInfo('selectedVideoCodec', codec);
	
	codec = null;
	event = null;
}


private function selectedAudioCodec_RBG_changeHandler(event:Event):void
{
	var codec:String = selectedAudioCodec_RBG.selectedValue.toString().toLowerCase();
	
	__appWideSingleton.setAppInfo('selectedAudioCodec', codec);
	
	codec = null;
	event = null;
}



private function selectedConnectionProtocol_RBG_itemClickHandler(event:Event):void
{
	var protocol:String = event.target.label.toString().toLowerCase();
	
	__appWideSingleton.setAppInfo('selectedConnectionProtocol', protocol);
	
	protocol = null;
	event = null;
}


private function selectedConnectionProtocol_RBG_changeHandler(event:Event):void
{
	var protocol:String = selectedConnectionProtocol_RBG.selectedValue.toString().toLowerCase();
	
	__appWideSingleton.setAppInfo('selectedConnectionProtocol', protocol);
	
	protocol = null;
	event = null;
}


private function selectedConnectionProtocol_RB_valueCommitHandler(event:Event):void
{
	var protocol:String = selectedConnectionProtocol_RBG.selectedValue.toString().toLowerCase();
	
	__appWideSingleton.setAppInfo('selectedConnectionProtocol', protocol);
	
	protocol = null;
	event = null;
}




//get rid of all brackets that a user might have put in
public function parseOutHTML(str:String):String
{
	// block <>'s
	do{
		str = str.replace(/</, "&lt;");
	}
	while(str.indexOf("<") != -1);
	do{
		str = str.replace(/>/, "&gt;");
	}
	while(str.indexOf(">") != -1);
	
	// block &#xa;
	do{
		str = str.replace("&#","");
	}
	while(str.indexOf("&#") != -1);
	
	return str;
}


/**
 * @usage    Check if the given email address string is valid or not
 * @param    email:String    Email address string that is to be checked
 * @return    Boolean        Returns true if valid email, false otherwise
 */
public function isValidEmail(email:String):Boolean
{
	var emailExpression:RegExp = /^[a-z][\w.-]+@\w[\w.-]+\.[\w.-]*[a-z][a-z]$/i;
	return emailExpression.test(email);
}









private function debugMsg(str:String):void
{
	AppWideDebug_Singleton.getInstance().newDebugMessage(this.id, str);
	
	str = null;
}

