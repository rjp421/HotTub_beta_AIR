/*
BongTVLive.com Hot Tub 2.0 beta7 by b0nghitter
*/
package scripts.net
{
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import events.CustomEvent;
	
	import me.whohacked.app.AppWideEventDispatcher_Singleton;
	
	
	public class UserListSOClient extends EventDispatcher
	{
		
		
		
		public function UserListSOClient(target:IEventDispatcher=null)
		{
			super(target);
			trace("|###| UserListSOClient |###|>  LOADED");
		}
		
		
		public function addUser(userObj:Object, isOnSync:Boolean=false):void
		{
			//trace("|###| UserListSOClient.addUser |###|>  userObj: "+userObj+"  userID: "+userObj.userID+"  userName: "+userObj.userName);
			
			// makes sure there is no userEnterLeave message, 
			// reset to false before adding to the userlist
			userObj.isOnSync = isOnSync;
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("userList_addUser", false,false, userObj));
			
			userObj = null;
		}
		
		
		public function removeUser(userObj:Object):void
		{
			//trace("|###| UserListSOClient.removeUser |###|>  userObj: "+userObj+"  userID: "+userObj.userID+" userObj.userName: "+userObj.userName);
			
			AppWideEventDispatcher_Singleton.getInstance().dispatchEvent(new CustomEvent("userList_removeUser", false,false, userObj));
			
			userObj = null;
		}
		
		
		
		
	}//end class
}//end package