import flash.events.Event;
import flash.events.MouseEvent;

import mx.events.ColorPickerEvent;
import mx.events.FlexEvent;

import spark.events.IndexChangeEvent;

import me.whohacked.app.AppWide_Singleton;
import me.whohacked.app.LocalSOManager_Singleton;


[@Embed(source='../assets/boldOnBtnImg.jpg')]
[Bindable]
private var boldOnBtnImg:Class;
[@Embed(source='../assets/boldOffBtnImg.jpg')]
[Bindable]
private var boldOffBtnImg:Class;
[@Embed(source='../assets/italicsOnBtnImg.jpg')]
[Bindable]
private var italicsOnBtnImg:Class;
[@Embed(source='../assets/italicsOffBtnImg.jpg')]
[Bindable]
private var italicsOffBtnImg:Class;
[@Embed(source='../assets/underlineOnBtnImg.jpg')]
[Bindable]
private var underlineOnBtnImg:Class;
[@Embed(source='../assets/underlineOffBtnImg.jpg')]
[Bindable]
private var underlineOffBtnImg:Class;

private var __appWideSingleton:AppWide_Singleton = AppWide_Singleton.getInstance();



private function fontControlBarCreationCompleteHandler(event:FlexEvent):void
{
	trace("|###| FontControlBar |###|>  LOADED");
	
	var localSOManager:LocalSOManager_Singleton = LocalSOManager_Singleton.getInstance();
	
	if (localSOManager.getLocalSOProperty('fontBold'))
	{
		boldImgBtn.source = new boldOnBtnImg();
	} else {
		boldImgBtn.source = new boldOffBtnImg();
	}
	
	if (localSOManager.getLocalSOProperty('fontItalics'))
	{
		italicsImgBtn.source = new italicsOnBtnImg();
	} else {
		italicsImgBtn.source = new italicsOffBtnImg();
	}
	
	if (localSOManager.getLocalSOProperty('fontUnderline'))
	{
		underlineImgBtn.source = new underlineOnBtnImg();
	} else {
		underlineImgBtn.source = new underlineOffBtnImg();
	}
	
	fontColor_CP.selectedColor = localSOManager.getLocalSOProperty('fontColor');
	fontSize_NS.value = localSOManager.getLocalSOProperty('fontSize');
	allFontSize_CB.selected = localSOManager.getLocalSOProperty('isAllFontSizeChecked');
	
	event = null;
}


private function boldImgBtn_clickHandler(event:MouseEvent):void
{
	if (boldImgBtn.source is boldOffBtnImg)
	{
		boldImgBtn.source = null;
		boldImgBtn.source = new boldOnBtnImg();
		
		parentApplication.lobby.chatPanel.chatTextFormat.isBold = true;
		
		__appWideSingleton.setAppInfo('fontBold', true);
	} else {
		boldImgBtn.source = null;
		boldImgBtn.source = new boldOffBtnImg();
		
		parentApplication.lobby.chatPanel.chatTextFormat.isBold = false;
		
		__appWideSingleton.setAppInfo('fontBold', false);
	}
	
	event = null;
}


private function italicsImgBtn_clickHandler(event:MouseEvent):void
{
	if (italicsImgBtn.source is italicsOffBtnImg)
	{
		italicsImgBtn.source = null;
		italicsImgBtn.source = new italicsOnBtnImg();
		
		parentApplication.lobby.chatPanel.chatTextFormat.isItalics = true;
		
		__appWideSingleton.setAppInfo('fontItalics', true);
	} else {
		italicsImgBtn.source = null;
		italicsImgBtn.source = new italicsOffBtnImg();
		
		parentApplication.lobby.chatPanel.chatTextFormat.isItalics = false;
		
		__appWideSingleton.setAppInfo('fontItalics', false);
	}
	
	event = null;
}


private function underlineImgBtn_clickHandler(event:MouseEvent):void
{
	if (underlineImgBtn.source is underlineOffBtnImg)
	{
		underlineImgBtn.source = null;
		underlineImgBtn.source = new underlineOnBtnImg();
		
		parentApplication.lobby.chatPanel.chatTextFormat.isUnderline = true;
		
		__appWideSingleton.setAppInfo('fontUnderline', true);
	} else {
		underlineImgBtn.source = null;
		underlineImgBtn.source = new underlineOffBtnImg();
		
		parentApplication.lobby.chatPanel.chatTextFormat.isUnderline = false;
		
		__appWideSingleton.setAppInfo('fontUnderline', false);
	}
	
	event = null;
}


private function fontColor_CP_changeHandler(event:ColorPickerEvent):void
{
	parentApplication.lobby.chatPanel.chatTextFormat.fontColor = "#"+fixedInt(fontColor_CP.selectedColor, '000000');
	
	__appWideSingleton.setAppInfo('fontColor', fontColor_CP.selectedColor);
	
	event = null;
}


private function fontSize_NS_valueFormatHandler(value:Number):String
{
	return value.toString();
}


private function fontSize_NS_changeHandler(event:Event):void
{
	parentApplication.lobby.chatPanel.chatTextFormat.fontSize = fontSize_NS.value;
	
	__appWideSingleton.setAppInfo('fontSize', fontSize_NS.value);
	
	event = null;
}


private function allFontSize_CB_changeHandler(event:Event):void
{
	__appWideSingleton.setAppInfo('isAllFontSizeChecked', allFontSize_CB.selected);
	
	event = null;
}


public function fixedInt(value:int, mask:String):String
{
	return String(mask + value.toString(16)).substr(-mask.length).toUpperCase();
}









