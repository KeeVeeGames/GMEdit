package yy;
import tools.Dictionary;
using tools.NativeString;

/**
 * Didn't think this one through
 * @author YellowAfterlife
 */
class YyTools {
	public static inline function isV22(q:YyBase):Bool {
		return q.modelName != null;
	}
	/** "GMIncludedFile" -> "includedFile" */
	public static function trimResourceType(type:String):String {
		return type.charAt(2).toLowerCase() + type.fastSubStart(3);
	}
	public static var allAssetTypes23:Array<String>;
	public static function isAllAssetTypes23(filters:Array<String>):Bool {
		var allTypes = allAssetTypes23;
		return (filters.length == allTypes.length
			&& filters.filter((s) -> (allTypes.indexOf(s) < 0)).length == 0
		);
	}
	public static var assetTypeMap23:Dictionary<String> = (function() {
		var dict = new Dictionary<String>();
		var all = [];
		function add(a:String, b:String):Void {
			all.push(a);
			dict[a] = b;
			dict[b] = a;
		}
		add("GMAnimCurve", "animcurve");
		add("GMFont", "font");
		add("GMObject", "object");
		add("GMPath", "path");
		add("GMRoom", "room");
		add("GMScript", "script");
		add("GMSequence", "sequence");
		add("GMShader", "shader");
		add("GMSound", "sound");
		add("GMSprite", "sprite");
		add("GMTileSet", "tileset");
		add("GMTimeline", "timeline");
		add("GMParticleSystem", "particle_asset");
		allAssetTypes23 = all;
		return dict;
	})();
	/** "GMObject" -> "object" */
	public static function kindOf23(resType:String):String {
		return assetTypeMap23.defget(resType, resType.substring(2).toLowerCase());
	}
}
