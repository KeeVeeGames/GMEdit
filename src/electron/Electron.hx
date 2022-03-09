package electron;
#if !starter
import electron.FontScanner.FontScannerFallback;
import electron.extern.ElectronRemote;

/*
 * ...
 * @author YellowAfterlife
 */
@:native("Electron_API") extern class Electron {
	public static inline function isAvailable():Bool {
		return Electron != null;
	}
	public static var shell:Dynamic;
	public static var remote:ElectronRemote;
	public static var clipboard:Clipboard;
	public static var ipcRenderer:Dynamic;
	public static inline function init():Void {
		inline function load(hxname:String, ename:String):Void {
			untyped window[hxname] = require(ename);
		}
		inline function set(hxname:String, ref:Dynamic):Void {
			if (ref == null) throw "Can't find " + hxname;
			untyped window[hxname] = ref;
		}
		inline function blank(hxname:String) {
			untyped window[hxname] = null;
		}
		if (untyped window.require != null) {
			load("Electron_API", "electron");
			load("Electron_FS", "fs");
			set("Electron_Dialog", remote.dialog);
			Dialog.initWorkarounds();
			set("Electron_IPC", ipcRenderer);
			set("Electron_Shell", shell);
			set("Electron_Menu", remote.Menu);
			set("Electron_MenuItem", remote.MenuItem);
			set("Electron_App", remote.app);
			set("Electron_BrowserWindow", remote.BrowserWindow);
			
			try {
				load("libFontScanner", "./native/font-scanner/index.js");
			} catch (x:Dynamic) {
				Main.console.warn("font-scanner failed to load: ", x);
				set("libFontScanner", FontScannerFallback);
			}
			
			function ensure(dir:String) {
				FileSystem.ensureDirSync(dir);
			}
			var path = AppTools.getPath("userData") + "/GMEdit";
			FileWrap.userPath = path;
			ensure(path);
			ensure(path + "/session");
			ensure(path + "/snippets");
			ensure(path + "/config");
			ensure(path + "/themes");
			ensure(path + "/plugins");
			ensure(path + "/api");
			ensure(path + "/api/v1");
			ensure(path + "/api/v2");
			ensure(path + "/api/live");
		} else {
			blank("Electron_API");
			set("Electron_FS", FileSystem.FileSystemBrowser);
			blank("Electron_IPC");
			blank("Electron_Shell");
			set("Electron_Menu", MenuFallback);
			set("Electron_MenuItem", MenuFallback.MenuItemFallback);
			blank("Electron_App");
			set("libFontScanner", FontScannerFallback);
		}
	}
}
#end
