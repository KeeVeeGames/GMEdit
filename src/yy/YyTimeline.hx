package yy;
import electron.FileWrap;
import gml.file.GmlFileExtra;
import haxe.io.Path;
import tools.Dictionary;
import yy.YyObject;
import electron.FileSystem;
import tools.NativeString;
import gml.*;
import parsers.GmlTimeline;

/**
 * ...
 * @author YellowAfterlife
 */
abstract YyTimeline(YyTimelineImpl) from YyTimelineImpl {
	public static var errorText:String;
	public static function getMomentPath(time:Int):String {
		return "moment_" + time + ".gml";
	}
	public function getCode(objPath:String, ?extras:Array<GmlFileExtra>){
		var dir = Path.directory(objPath);
		var out = "";
		var errors = "";
		for (moment in this.momentList) {
			var time = moment.moment;
			var rel = getMomentPath(time);
			var full = Path.join([dir, rel]);
			if (extras != null) extras.push(new GmlFileExtra(full));
			var code = FileWrap.readTextFileSync(full);
			if (out != "") out += "\n\n";
			out += "#moment " + time;
			code = ~/^\/\/\/\s*@desc[ \t]+(.*)\r?\n/g.map(code, function(rx:EReg) {
				out += " " + rx.matched(1);
				return "";
			});
			out += "\n" + NativeString.trimRight(code);
		}
		return out;
	}
	public function setCode(objPath:String, gmlCode:String):Bool {
		var dir = Path.directory(objPath);
		var newData = GmlTimeline.parse(gmlCode, GmlVersion.v2);
		if (newData == null) {
			errorText = GmlTimeline.parseError;
			return false;
		}
		var v23 = Project.current.isGMS23;
		//
		var oldList = this.momentList;
		var oldMap = [];
		for (mm in oldList) oldMap[mm.moment] = mm;
		//
		var newList:Array<{ moment:YyTimelineMoment, code:String }> = [];
		var newMap = [];
		//
		for (item in newData) {
			var time = item.moment;
			// try to reuse existing moments where possible:
			var mm = oldMap[time];
			if (mm == null) {
				if (v23) mm = {
					moment: time,
					evnt: {
						isDnD: false,
						eventNum: time,
						eventType: 0,
						collisionObjectId: null,
						resourceVersion: "1.0",
						name: "",
						tags: [],
						resourceType: "GMEvent",
					},
					resourceVersion: "1.0",
					name: "",
					tags: [],
					resourceType: "GMMoment",
				}; else mm = {
					id: new YyGUID(),
					modelName: "GMMoment",
					mvc: "1.0",
					name: "",
					moment: time,
					evnt: {
						id: new YyGUID(),
						modelName: "GMEvent",
						mvc: "1.0",
						IsDnD: false,
						eventtype: 0,
						enumb: time,
						collisionObjectId: YyGUID.zero,
						m_owner: this.id,
					},
				};
			}
			newMap[time] = mm;
			newList.push({ moment: mm, code: item.code[0] });
		}
		// remove moment files that are no longer used:
		for (mm in oldList) if (newMap[mm.moment] == null) {
			var full = Path.join([dir, getMomentPath(mm.moment)]);
			if (FileWrap.existsSync(full)) FileWrap.unlinkSync(full);
		}
		// write used moments:
		this.momentList = [];
		for (item in newList) {
			var mm = item.moment;
			var full = Path.join([dir, getMomentPath(mm.moment)]);
			FileWrap.writeTextFileSync(full, item.code);
			this.momentList.push(mm);
		}
		//
		return true;
	}
}
typedef YyTimelineImpl = {
	>YyBase,
	name:String,
	momentList:Array<YyTimelineMoment>,
}
typedef YyTimelineMoment = {
	>YyBase,
	moment:Int,
	name:String,
	evnt:YyObjectEvent,
}
