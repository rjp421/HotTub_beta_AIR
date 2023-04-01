/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/

/* THIS CLASS IS BASED ON CODE FROM http://www.FMSGuru.com A GREAT RESOURCE FOR FMS */

package events
{
	import flash.events.Event;
	
	public class CustomEvent extends Event
	{
		
		public var eventObj:Object;
		
		
		public function CustomEvent(type:String, bubbles:Boolean, cancelable:Boolean, _eventObj:Object)
		{
			//trace("|###| CustomEvent |###|>  LOADED | type: "+type+" eventObj: "+_eventObj);
			super(type, bubbles, cancelable);
			
			eventObj = _eventObj;
		}
		
		public function cloneCustomEvent():CustomEvent
		{
			return new CustomEvent(type, bubbles, cancelable, eventObj);
		}
		
		override public function toString():String
		{
			return formatToString("CustomEvent", "type", "bubbles", "cancelable", "eventPhase", "eventObj");
		}
		
		
		
	}
}