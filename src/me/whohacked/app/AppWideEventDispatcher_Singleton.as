package me.whohacked.app
{
	
	import flash.events.EventDispatcher;
	
	
	public class AppWideEventDispatcher_Singleton extends EventDispatcher
	{
		
		
		private var __initialized:Boolean = false;
		private static var __instance:AppWideEventDispatcher_Singleton;
		
		
		
		
		public function AppWideEventDispatcher_Singleton()
		{
			if (__instance)
				throw new Error("AppWideEventDispatcher_Singleton is a singleton class, use .getInstance() instead!");
			
			init(); // instantiate the initial components
		}
		
		
		private function init():void // instantiate the static variables
		{
			if (!__initialized) // if this Singleton has not been instantiated yet
			{
				__initialized = true; // the class has now been instantiated
			}
		}
		
		
		public static function getInstance():AppWideEventDispatcher_Singleton
		{
			if (__instance==null)
			{
				__instance = new AppWideEventDispatcher_Singleton();
			}
			return __instance;
		}
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			AppWideDebug_Singleton.getInstance().newDebugMessage(this.toString(), str);
		}
		
	} // end class
} // end package