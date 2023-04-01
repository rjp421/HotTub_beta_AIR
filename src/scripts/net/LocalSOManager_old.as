/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
package scripts.net
{
	import flash.events.ErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.net.SharedObject;

	public class LocalSOManager_old
	{
		
		public var localSO:SharedObject = SharedObject.getLocal("HotTub");
		
		
		public function LocalSOManager_old()
		{
			
			try {
				//localSO.clear();
				
				trace("Original SharedObject size is " + localSO.size + " bytes.");
				
				if (localSO.size == 0)
				{
					if (!localSO.hasEventListener(NetStatusEvent.NET_STATUS)) { localSO.addEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus); }
					if (!localSO.hasEventListener(ErrorEvent.ERROR)) { localSO.addEventListener(ErrorEvent.ERROR, onSOError); }
					if (!localSO.data.ignores)
					{
						var ignores:Object = new Object();
						localSO.data.ignores = ignores;
						ignores = null;
					}
					
					setupLocalSO();
				}
/*				for (var i:Object in localSO.data)
				{
					trace("######################>>>>>>>  "+ i + ":\t" + localSO.data[i]);
				}
				i = null;
*/			} catch (error:*) {
				trace("### LOCAL SO ERROR ###");
				if (localSO.hasEventListener(NetStatusEvent.NET_STATUS)) { localSO.removeEventListener(NetStatusEvent.NET_STATUS, onNetStreamStatus); }
				if (localSO.hasEventListener(ErrorEvent.ERROR)) { localSO.removeEventListener(ErrorEvent.ERROR, onSOError); }
				error = null;
			}
		}
		
		
		private function onNetStreamStatus(e:NetStatusEvent):void
		{
			var c:String = e.info.code;
			
			trace("onNetStreamStatus######################>>>>>>>  " + c);
			
			switch (c)
			{
				case "SharedObject.Flush.Failed" :
					trace("### LOCAL SO FLUSH FAILED ###");
					break;
				case "SharedObject.Flush.Success" :
					trace("### LOCAL SO FLUSH SUCCESS ###");
					for (var i:Object in localSO.data) {
						trace(i + ":\t" + localSO.data[i]);
					}
					i = null;
					break;
			}
			e = null;
			c = null;
		}
		
		
		// set the defaults
		private function setupLocalSO():void
		{
			trace("### setupLocalSO ###|>  ");
			
			setLocalSOProperty("login","");
			setLocalSOProperty("pass","");
			setLocalSOProperty("adminType","notadmin");
			setLocalSOProperty("defaultQuality","high");
			setLocalSOProperty("debugMode",false);
			setLocalSOProperty("version","0");
			setLocalSOProperty("isSavePasswordChecked",false);
			setLocalSOProperty("isAutoFillCamsChecked",true);
			setLocalSOProperty("isAllCamsOffChecked",false);
			setLocalSOProperty("isAllAudioOffChecked",true);
			setLocalSOProperty("isAllFontSizeChecked",true);
			setLocalSOProperty("isBanned",false);
			setLocalSOProperty("fontBold",false);
			setLocalSOProperty("fontItalics",false);
			setLocalSOProperty("fontUnderline",false);
			setLocalSOProperty("fontColor",000000);
			setLocalSOProperty("fontSize",14);
			
			var ignores:Object = new Object();
			var names:Object = new Object();
			var acctids:Object = new Object();
			
			ignores.names = names;
			ignores.acctids = acctids;
			
			setLocalSOProperty("ignores", ignores);
			
			localSO.flush();
			
			ignores = null;
			names = null;
			acctids = null;
		}
		
		
		public function setLocalSOProperty(property:String, value:*):void
		{
			trace("### setLocalSOProperty ###|>  current size: "+localSO.size+"  "+property+": "+(property != 'pass') ? value : '');
			
			if (localSO.size != 0)
			{
				localSO.data[property] = value;
				localSO.flush();
			}
			
			property = null;
			value = null;
		}
		
		
		public function clearIgnores():void
		{
			if (localSO.data.ignores)
			{
				localSO.data.ignores = null;
				
				var ignores:Object = new Object();
				var names:Object = new Object();
				var acctids:Object = new Object();
				
				ignores.names = names;
				ignores.acctids = acctids;
				localSO.data.ignores = ignores;
				localSO.flush();
				
				ignores = null;
				names = null;
				acctids = null;
			}
		}
		
		private function onSOError(e:ErrorEvent):void
		{
			//trace("### LOCAL SO ERROR ###|> "+e.error.code);
			e = null;
		}
		
		
	}//end class
}//end package