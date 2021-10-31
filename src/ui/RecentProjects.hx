package ui;
import electron.AppTools;
import electron.Electron;
import electron.FileSystem;
import electron.FileWrap;
import haxe.Json;
import haxe.io.Path;
import tools.NativeString;
import ui.treeview.TreeView;

/**
 * Manages a list of recently opened projects.
 * @author YellowAfterlife
 */
class RecentProjects {
	private static function get():Array<String> {
		try {
			var curr:Array<String> = FileWrap.readConfigSync("session",  "recent-projects");
			if (!Std.is(curr, Array)) return [];
			for (i in 0 ... curr.length) {
				curr[i] = tools.PathTools.ptNoBS(curr[i]);
			}
			return curr;
		} catch (_:Dynamic) return [];
	}
	private static function set(list:Array<String>) {
		FileWrap.writeConfigSync("session", "recent-projects", list);
	}
	public static function clear():Void {
		set([]);
		if (Electron.isAvailable()) AppTools.clearRecentDocuments();
	}
	public static function add(path:String) {
		var curr = get();
		curr.remove(path);
		curr.unshift(path);
		if (curr.length > Preferences.current.recentProjectCount) curr.pop();
		if (Electron.isAvailable()) AppTools.addRecentDocument(path);
		set(curr);
	}
	public static function remove(path:String) {
		var curr = get();
		curr.remove(path);
		set(curr);
	}
	public static function show() {
		TreeView.clear();
		var el = TreeView.element;
		var lookup = [];
		if (electron.Electron != null) for (path in get()) {
			var pair = tools.PathTools.ptDetectProject(path);
			var name = pair.name;
			lookup.push(name);
			var pj = TreeView.makeProject(name, path);
			FileSystem.exists(path, function(e) {
				if (e != null) {
					pj.setAttribute("data-missing", "true");
					return;
				}
				if (!NativeString.startsWith(pair.version.name, "v2")) return;
				var thumbIcon = path + ".png";
				FileSystem.exists(thumbIcon, function(e) {
					if (e == null) {
						TreeView.setThumb(path, "file:///" + thumbIcon);
						return;
					}
					var tplIcon = Path.directory(path) + "/options/main/template_icon.png";
					FileSystem.exists(tplIcon, function(e) {
						if (e == null) TreeView.setThumb(path, "file:///" + tplIcon);
					});
				});
			});
			el.appendChild(pj);
		}
		gml.GmlAPI.gmlLookupList = lookup;
	}
}
