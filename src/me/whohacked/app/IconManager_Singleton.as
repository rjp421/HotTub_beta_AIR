/*
	whohacked.me - rjp421@gmail.com
*/
package me.whohacked.app
{
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class IconManager_Singleton extends EventDispatcher
	{
		
		// add an HTTPService to get dynamic icons then return it as a BitmapImage
		// create a contentCache for better performance
		private var __initialized:Boolean = false;
		private static var __instance:IconManager_Singleton;
		
		
		// static icons
		
		// CamSpot controls
		/*
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/x.png')]
		private var __x_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/arrow.png')]
		private var __arrow_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/fullscreen.png')]
		private var __fullscreen_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/exitfullscreen.png')]
		private var __exitfullscreen_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/videoIsOn.png')]
		private var __videoIsOn_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/videoIsOff.png')]
		private var __videoIsOff_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/audioIsOn.png')]
		private var __audioIsOn_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/camspot/audioIsOff.png')]
		private var __audioIsOff_Img:Class;
		
		
		// chat controls
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/font/boldIsOff.png')]
		private var __boldIsOff_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/font/boldIsOn.png')]
		private var __boldIsOn_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/font/italicsIsOff.png')]
		private var __italicsIsOff_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/font/italicsIsOn.png')]
		private var __italicsIsOn_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/font/underlineIsOff.png')]
		private var __underlineIsOff_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/font/underlineIsOn.png')]
		private var __underlineIsOn_Img:Class;
		
		// default emoticons, add more
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/emoticons/emoticon_smile.png')]
		private var __emoticon_smile_Img:Class;
		
		// app icons
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/on.png')]
		private var __app_on_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/off.png')]
		private var __app_off_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/cog.png')]
		private var __app_cog_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/optionsBtn.png')]
		private var __app_options_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/connect.png')]
		private var __app_connect_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/disconnect.png')]
		private var __app_disconnect_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/comment.png')]
		private var __app_comment_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/comments.png')]
		private var __app_comments_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/help.png')]
		private var __app_help_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/error.png')]
		private var __app_error_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/warning.png')]
		private var __app_warning_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/information.png')]
		private var __app_info_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/accept.png')]
		private var __app_accept_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/cancel.png')]
		private var __app_cancel_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/door.png')]
		private var __app_door_Img:Class;		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/door_in.png')]
		private var __app_door_in_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/door_out.png')]
		private var __app_door_out_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/door_open.png')]
		private var __app_door_open_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/arrow_in.png')]
		private var __app_arrow_in_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/arrow_out.png')]
		private var __app_arrow_out_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/arrow_inout.png')]
		private var __app_arrow_inout_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/arrow_refresh.png')]
		private var __app_arrow_refresh_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/arrow_undo.png')]
		private var __app_arrow_undo_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/application_edit.png')]
		private var __app_application_edit_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/application_side_list.png')]
		private var __app_application_side_list_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/page_white_flash.png')]
		private var __app_page_white_flash_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/page_white_actionscript.png')]
		private var __app_page_white_actionscript_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/status_online.png')]
		private var __app_status_online_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/status_offline.png')]
		private var __app_status_offline_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/status_away.png')]
		private var __app_status_away_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/status_busy.png')]
		private var __app_status_busy_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/user.png')]
		private var __app_user_blue_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/user_green.png')]
		private var __app_user_green_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/user_red.png')]
		private var __app_user_red_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/user_orange.png')]
		private var __app_user_orange_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/user_gray.png')]
		private var __app_user_gray_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/user_suit.png')]
		private var __app_user_suit_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/group.png')]
		private var __app_group_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/television.png')]
		private var __app_tv_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/computer.png')]
		private var __app_computer_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/computer_key.png')]
		private var __app_computer_key_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/computer_delete.png')]
		private var __app_logout_Img:Class;

		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/webcam.png')]
		private var __app_webcam_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/microphone.png')]
		private var __app_mic_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/ear.png')]
		private var __app_ear_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/film.png')]
		private var __app_film_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/tick.png')]
		private var __app_tick_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/cross.png')]
		private var __app_cross_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/lock.png')]
		private var __app_lock_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/layout.png')]
		private var __app_layout_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/application_double.png')]
		private var __app_double_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/popout_window.png')]
		private var __app_popout_window_Img:Class;
		
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/comment_rotated.png')]
		private var __app_comment_rotated_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/computer_rotated.png')]
		private var __app_computer_rotated_Img:Class;
		[Embed('/me/whohacked/assets/images/dpi160/icons/chat/app/television_rotated.png')]
		private var __app_tv_rotated_Img:Class;
		*/
		
		[Embed('../../../assets/tubbg-green.jpg')]
		private var __app_tubbg_Img:Class;
		
		[Embed('../../../assets/ignoredIcon.png')]
		private var __app_userList_ignored_Img:Class;
		[Embed('../../../assets/userlist-users.png')]
		private var __app_userList_users_Img:Class;
		[Embed('../../../assets/userlist-guest.png')]
		private var __app_userList_guest_Img:Class;
		[Embed('../../../assets/userlist-member.png')]
		private var __app_userList_member_Img:Class;
		[Embed('../../../assets/userlist-rm.png')]
		private var __app_userList_rm_Img:Class;
		[Embed('../../../assets/userlist-ra.png')]
		private var __app_userList_ra_Img:Class;
		[Embed('../../../assets/userlist-rh.png')]
		private var __app_userList_rh_Img:Class;
		[Embed('../../../assets/userlist-ga.png')]
		private var __app_userList_ga_Img:Class;
		[Embed('../../../assets/userlist-sa.png')]
		private var __app_userList_sa_Img:Class;
		
		[Embed('../../../assets/x.png')]
		private var __app_x_Img:Class;
		[Embed('../../../assets/arrow.png')]
		private var __app_arrow_Img:Class;
		
		[Embed('../../../assets/cameraOn.png')]
		private var __app_cameraOn_Img:Class;
		[Embed('../../../assets/cameraOff.png')]
		private var __app_cameraOff_Img:Class;
		[Embed('../../../assets/audioOn.png')]
		private var __app_audioOn_Img:Class;
		[Embed('../../../assets/audioOff.png')]
		private var __app_audioOff_Img:Class;
		[Embed('../../../assets/videoOn.png')]
		private var __app_videoOn_Img:Class;
		[Embed('../../../assets/videoOff.png')]
		private var __app_videoOff_Img:Class;
		
		[Embed('../../../assets/webcam.png')]
		private var __app_webcam_Img:Class;
		[Embed('../../../assets/audio.png')]
		private var __app_audio_Img:Class;
		
		[Embed('../../../assets/door_in.png')]
		private var __app_door_in_Img:Class;
		[Embed('../../../assets/door_out.png')]
		private var __app_door_out_Img:Class;
		[Embed('../../../assets/information.png')]
		private var __app_info_Img:Class;
		[Embed('../../../assets/film.png')]
		private var __app_film_Img:Class;
		[Embed('../../../assets/film_delete.png')]
		private var __app_film_delete_Img:Class;
		[Embed('../../../assets/webcam_delete.png')]
		private var __app_webcam_delete_Img:Class;
		[Embed('../../../assets/lightning.png')]
		private var __app_lightning_Img:Class;
		[Embed('../../../assets/lightning_add.png')]
		private var __app_lightning_add_Img:Class;
		[Embed('../../../assets/lightning_delete.png')]
		private var __app_lightning_delete_Img:Class;
		[Embed('../../../assets/chart_line.png')]
		private var __app_chart_line_Img:Class;
		[Embed('../../../assets/chart_line_add.png')]
		private var __app_chart_line_add_Img:Class;
		[Embed('../../../assets/chart_line_delete.png')]
		private var __app_chart_line_delete_Img:Class;
		[Embed('../../../assets/new.png')]
		private var __app_new_Img:Class;
		[Embed('../../../assets/cog.png')]
		private var __app_settings_Img:Class;
		[Embed('../../../assets/television.png')]
		private var __app_television_Img:Class;
		[Embed('../../../assets/camera.png')]
		private var __app_camera_Img:Class;
		[Embed('../../../assets/music.png')]
		private var __app_music_Img:Class;
		[Embed('../../../assets/eye.png')]
		private var __app_eye_Img:Class;
		[Embed('../../../assets/speaker.png')]
		private var __app_speaker_Img:Class;
		[Embed('../../../assets/cam.png')]
		private var __app_cam_Img:Class;
		[Embed('../../../assets/mic.png')]
		private var __app_mic_Img:Class;
		[Embed('../../../assets/refillcams.png')]
		private var __app_refillCams_Img:Class;
		[Embed('../../../assets/refillcams-green.png')]
		private var __app_refillCams_green_Img:Class;
		
		
		// static icons
		[Embed('/assets/volume_full.png')]
		private var __app_vumeter_Img:Class;
		
		
		
		
		
		
		
		public function IconManager_Singleton()
		{
			if (__instance)
				throw new Error("IconManager is a singleton class, use .getInstance() instead!");
			
			init(); // instantiate the initial components
		}
		
		private function init():void // instantiate the static variables
		{
			if (!__initialized) // if this Singleton has not been instantiated yet
			{
				// instantiate each icon image
				__initialized = true; // the class has now been instantiated
			}
		}
		
		public static function getInstance():IconManager_Singleton
		{
			if(__instance==null)
			{
				__instance = new IconManager_Singleton();
			}
			return __instance;
		}
		
		public function getIcon(iconName:String):*
		{
			var __retVal:* = null;
			if (__instance)
			{
				//var val1:String = '__'+iconName+'_Img';
				//var val2:String = __instance['__'+iconName+'_Img'].toString;
				//var val3:* = __instance['__'+iconName+'_Img'];
				
				if (__instance['__'+iconName+'_Img'] == null)
				{
					__instance['__'+iconName+'_Img'] = new __instance['__'+iconName+'_Img']();
				}
				__retVal = this['__'+iconName+'_Img'];
			}
			return __retVal;
		}
		
		
		public function getEmoticon(iconName:String):*
		{
			var __retVal:* = null;
			if (__instance)
			{
				//var val1:String = '__'+iconName+'_Img';
				//var val2:String = __instance['__'+iconName+'_Img'].toString;
				//var val3:* = __instance['__'+iconName+'_Img'];
				
				if (__instance['__emoticon_'+iconName+'_Img'] == null)
				{
					__instance['__emoticon_'+iconName+'_Img'] = new __instance['__emoticon_'+iconName+'_Img']();
				}
				__retVal = this['__emoticon_'+iconName+'_Img'];
			}
			return __retVal;
		}
		
		
		// TODO
		public function getEmoticonFromURL(iconName:String, fileType:String):*
		{
			var __retVal:* = null;
			var iconURL:String = '/assets/images/dpi160/icons/chat/emoticons/emoticon_'+iconName+'.'+fileType;
			
			if (__instance)
			{
				var bitmapData:BitmapData;
				
				var loader:Loader = new Loader();
				var urlLoader:URLLoader = new URLLoader();
				var urlRequest:URLRequest = new URLRequest(iconURL);
				
				urlLoader.addEventListener(Event.COMPLETE, urlLoader_complete);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.load(urlRequest);
				
				// Here we translate the bytes into a Bitmap
				function urlLoader_complete(event:Event):void
				{
					urlLoader.removeEventListener(Event.COMPLETE, urlLoader_complete);
					
					var bytes:ByteArray = URLLoader(event.target).data;
					
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loader_complete);
					loader.loadBytes(bytes);
				}
				
				// And finally, we save off the bytes and set the cursor 
				function loader_complete(event:Event):void
				{
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loader_complete);
					
					bitmapData = Bitmap(event.target.content).bitmapData;
					
					//CursorManager.setCursor(MyLoadedImageClass, CursorManagerPriority.HIGH);
					__retVal = Bitmap(event.target.content);
				}
			}
			
			return __retVal;
		}
		
		
		
		
		
		
		
		
		
		
		private function debugMsg(str:String):void
		{
			var _awd:AppWideDebug_Singleton = AppWideDebug_Singleton.getInstance();
			_awd.newDebugMessage("IconManager",str);
		}	
		
		
	} // end class
} // end package