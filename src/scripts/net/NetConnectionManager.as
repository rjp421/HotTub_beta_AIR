/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/

/* THIS CLASS IS BASED ON CODE FROM http://www.FMSGuru.com A GREAT RESOURCE FOR FMS */

package scripts.net
{
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	
	import events.CustomEvent;
	
	import me.whohacked.app.AppWideDebug_Singleton;
	import me.whohacked.app.AppWideEventDispatcher_Singleton;
	
	
	
	// TODO
	// separate from the NetConnection(s)
	public class NetConnectionManager extends NetConnection
	{
		
		public function NetConnectionManager():void
		{
			debugMsg("->  LOADED");
			super();
			addEventListener(NetStatusEvent.NET_STATUS, onConnectionStatus, false,0,true);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false,0,true);
			addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError, false,0,true);
			addEventListener(IOErrorEvent.IO_ERROR, onIOError, false,0,true);
		}
		
		
		public function createNetConnection(command:String, ... arguments):void
		{
			arguments.unshift(command);
			super.connect.apply(this, arguments);
			debugMsg("createNetConnection->  command: "+command+"  arguments: "+arguments+"  proxyType: "+proxyType+"  uri: "+uri);
		}
		
		
		protected function onConnectionStatus(event:NetStatusEvent):void
		{
			debugMsg("onConnectionStatus->  " + event.info.code);
			
			var infoObjectsArray:Array = event.info.code.split(".");
			
			if (infoObjectsArray[1] == "Connect")
			{
				switch (infoObjectsArray[2])
				{
					case "Success":
						dispatchEvent(new CustomEvent("onConnect", false, false, event.info));
						debugMsg("onConnectionStatus->  <CONNECTION SUCCESSFULL>  protocol: "+protocol+"  usingTLS: "+usingTLS+"  proxyType: "+proxyType+"  connectedProxyType: "+connectedProxyType+"  uri: "+uri);
						
						AppWideEventDispatcher_Singleton.getInstance().addEventListener("doBWCheck", doBWCheck, false,0,true);
						AppWideEventDispatcher_Singleton.getInstance().addEventListener("onBWDone", onBWDoneHandler, false,0,true);
						
						break;
					case "Failed":
						dispatchEvent(new CustomEvent("onFailed", false, false, event.info));
						debugMsg("onConnectionStatus->  <CONNECTION FAILED>  proxyType: "+proxyType+"  uri: "+uri);
						break;
					case "Rejected":
						dispatchEvent(new CustomEvent("onRejected", false, false, event.info));
						debugMsg("onConnectionStatus->  <CONNECTION REJECTED>  proxyType: "+proxyType+"  uri: "+uri);
						break;
					case "Closed":
						dispatchEvent(new CustomEvent("onClosed", false, false, event.info));
						debugMsg("onConnectionStatus->  <CONNECTION CLOSED>  proxyType: "+proxyType+"  uri: "+uri);
						
						AppWideEventDispatcher_Singleton.getInstance().removeEventListener("onBWDone", onBWDoneHandler);
						AppWideEventDispatcher_Singleton.getInstance().removeEventListener("doBWCheck", doBWCheck);
						
						break;
					default:
						debugMsg("onConnectionStatus->  <UNHANDLED>  "+(event.info.code ? "  code: "+event.info.code : "")+(super.connected ? "  protocol: "+protocol+"  usingTLS: "+usingTLS+"  proxyType: "+proxyType+"  connectedProxyType: "+connectedProxyType : "")+"  uri: "+uri);
						break;
				}
			}
			
			infoObjectsArray.splice(0);
			infoObjectsArray = null;
			event = null;
		}		
		
		
		protected function onSecurityError(event:SecurityErrorEvent):void
		{
			debugMsg("onSecurityError->  " + event.text);
			
			event = null;
		}
		
		
		protected function onAsyncError(event:AsyncErrorEvent):void
		{
			debugMsg("onAsyncError->  " + event.error.message);
			
			event = null;
		}
		
		
		protected function onIOError(event:IOErrorEvent):void
		{
			debugMsg("onIOError->  " + event.text);
			
			event = null;
		}
		
		
		public function doBWCheck(event:Event):Number
		{
			debugMsg("doBWCheck->  CALLING checkBandwidth");
			
			this.client.dispatchEvent(new CustomEvent("receiveMessage", false,false, {isAdminMessage:true, msg:"Starting bandwidth check...."}));
			/*
			// get the bandwidth limit from the server
			var responder:Responder = new Responder(getBandwidthLimitResponder);
			
			function getBandwidthLimitResponder(info:Object):void
			{
			debugMsg("getBandwidthLimitResponder->  " + info);
			for (var i:String in info) { trace(i + " - " + info[i]); }
			}
			
			parentApplication.loginPanel.nc.call("getBandwidthLimit", responder, 0);
			*/
			
			// check the bandwidth to the server
			this.call("checkBandwidth", null);
			
			event = null;
			
			return 0;
		}
		
		
		public function onBWDoneHandler(event:CustomEvent):void
		{
			//debugMsg("onBWDoneHandler->  CALLED");
			/*
			var bitrate:Number = 0;
			var latency:Number = 0;
			if (event.eventObj.bitrate > 0)
				bitrate = event.eventObj.bitrate;
			if (event.eventObj.latency)
				latency = event.eventObj.latency;
			
			debugMsg("onBWDoneHandler->  "+bitrate+" Kb/s,  "+0.125*bitrate+" KB/s"+(latency>0 ? ",  latency: "+latency : ""));
			*/
			event = null;
		}
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			AppWideDebug_Singleton.getInstance().newDebugMessage("NetConnectionManager", str);
			
			str = null;
		}
		
	}// end class
}// end package