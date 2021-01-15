package gml.type;
import ace.AceGmlTools;
import gml.type.GmlType;
import haxe.ds.ReadOnlyArray;
import parsers.GmlReader;
import tools.Dictionary;
import tools.JsTools;
using tools.NativeString;
import ace.extern.AceTokenType;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class GmlTypeTools {
	public static var kindMap:Dictionary<AceTokenType> = Dictionary.fromKeys([
		"Any", "any", "undefined",
		"number", "string", "bool", // primitives
		"array", "type", "Array", "Type",
		"ds_list", "ds_map", "ds_grid",
	], "namespace");
	
	public static function getNamespace(t:GmlType):String {
		return switch (t) {
			case null: null;
			case TInst(name, _, KCustom): name;
			default: null;
		}
	}
	
	public static function getKind(t:GmlType):Null<GmlTypeKind> {
		return switch (t) {
			case null: null;
			case TInst(_, _, k): k;
			default: null;
		}
	}
	
	public static inline function isNullable(t:GmlType):Bool {
		return getKind(t) == KNullable;
	}
	
	public static inline function isType(t:GmlType):Bool {
		return getKind(t) == KType;
	}
	
	public static inline function isArray(t:GmlType):Bool {
		return getKind(t) == KArray;
	}
	
	public static function unwrapParam(t:GmlType):GmlType {
		return switch (t) {
			case null: null;
			case TInst(_, p, _): p[0];
			default: null;
		}
	}
	
	
	public static function mapArray(arr:ReadOnlyArray<GmlType>, f:GmlType->GmlType):ReadOnlyArray<GmlType> {
		var out:Array<GmlType> = null;
		for (i => t1 in arr) {
			var t2 = f(t1);
			if (t2 != t1) {
				if (out == null) out = arr.slice(0, i);
				out.push(t2);
			} else {
				if (out != null) out.push(t1);
			}
		}
		return out != null ? out : arr;
	}
	public static function map(t:GmlType, f:GmlType->GmlType):GmlType {
		switch (t) {
			case TInst(n1, tp1, k1): {
				var tp2 = mapArray(tp1, f);
				return tp2 != tp1 ? TInst(n1, tp2, k1) : t;
			};
			case TEither(et1): {
				var et2 = mapArray(et1, f);
				return et2 != et1 ? TEither(et2) : t;
			};
			default: return t;
		}
	}
	
	public static function mapTemplateTypes(t:GmlType, templateTypes:Array<GmlType>):GmlType {
		function f(t:GmlType):GmlType {
			return switch (t) {
				case null: null;
				case TTemplate(ind): return templateTypes[ind];
				default: t.map(f);
			}
		}
		return f(t);
	}
	
	public static function equals(a:GmlType, b:GmlType, ?tpl:Array<GmlType>):Bool {
		switch (b) {
			case TTemplate(i):
				if (tpl == null) return true;
				if (tpl[i] != null) {
					return equals(a, tpl[i]);
				}  else {
					// this is clearly not a very good idea
					if (a != null) tpl[i]  = a;
					return true;
				}
			default:
		}
		switch (a) {
			case null: return b == null;
			case TInst(n1, tp1, k1):
				switch (b) {
					case null: return false;
					case TInst(n2, tp2, k2):
						if (k1 != k2) return false;
						if (k1 == KCustom && n1 != n2) return false;
						for (i => p1 in tp1) {
							if (!p1.equals(tp2[i], tpl)) return false;
						}
						return true;
					default: return false;
				}
			case TEither(et1):
				var et2 = switch (b) {
					case null: return false;
					case TEither(et): et;
					default: return false;
				}
				var en = et1.length;
				if (en != et2.length) return false;
				var ei1 = -1;
				while (++ei1 < en) {
					var et = et1[ei1];
					var ei2 = -1;
					while (++ei2 < en) {
						if (et.equals(et2[ei2], tpl)) break;
					}
					if (ei2 >= en) return false;
				}
				return true;
			case TAnon(fm1):
				var fm2 = switch (b) {
					case null: return false;
					case TAnon(f): f;
					default: return false;
				}
				var n1 = 0;
				for (name => field in fm1.fields) {
					n1 += 1;
					if (!field.type.equals(fm2.fields[name].type, tpl)) return false;
				}
				return n1 == fm2.fields.size();
			case TTemplate(i1): return false;
		}
	}
	
	static function canCastToAnyOf(from:GmlType, toArr:ReadOnlyArray<GmlType>, ?tpl:Array<GmlType>):Bool {
		for (to in toArr) if (canCastTo(from, to, tpl)) return true;
		return false;
	}
	
	public static function canCastTo(from:GmlType, to:GmlType, ?tpl:Array<GmlType>):Bool {
		if (from == null || to == null) return true;
		if (from == to) return true;
		if (from.equals(to, tpl)) return true;
		if (to.isNullable() && !from.isNullable() && from.canCastTo(to.unwrapParam(), tpl)) return true;
		
		switch ([from, to]) {
			case [TEither(et1), TEither(et2)]: { // each member of from must cast to some member of to
				for (t1 in et1) if (!canCastToAnyOf(t1, et2, tpl)) return false;
				return true;
			}
			case [_, TEither(et2)]: return canCastToAnyOf(from, et2, tpl);
			case [TInst(n1, p1, k1), TInst(n2, p2, k2)]: {
				if (k1 == k2 && n1 == n2) {
					var i = p1.length;
					while (--i >= 0) if (p2[i] != null) break;
					if (i < 0) return true; // allow Array<T>->Array or Array<T>->Array<?>
				}
			};
			case [TAnon(a1), TInst(n2, [], KCustom)]: {
				// todo: see if anon can be unified
			}
			default:
		}
		return false;
	}
	
	public static function toString(type:GmlType, ?templateTypes:Array<GmlType>):String {
		switch (type) {
			case null: return "?";
			case TInst(name, params, kind): {
				var s:String = name;
				if (params.length > 0) {
					s += "<";
					for (i => tp in params) {
						if (i > 0) s += ", ";
						s += toString(tp);
					}
					s += ">";
				}
				return s;
			};
			case TEither(types): {
				var s = "(";
				for (i => tp in types) {
					if (i > 0) s += "|";
					s += toString(tp);
				}
				return s + ")";
			};
			case TAnon(anon): {
				var s = "{ ";
				var sep = false;
				anon.fields.forEach(function(k, fd) {
					if (sep) s += ", "; else sep = true;
					s += k + ": " + toString(fd.type);
				});
				if (sep) s += " ";
				return s + "}";
			};
		case TTemplate(ind):
			var tt = JsTools.nca(templateTypes, templateTypes[ind]);
			return tt != null ? toString(tt) : 'TN<$ind>';
		}
	}
	
	public static function patchTemplateNames(s:String, templateNames:Array<String>):String {
		if (templateNames == null) return s;
		for (i => tn in templateNames) {
			s = s.replaceExt(tn.getWholeWordRegex("g"), 'TN<T$i>');
		}
		return s;
	}
	
	public static function getSelfCallDoc(self:GmlType, imp:GmlImports):GmlFuncDoc {
		return JsTools.nca(self, AceGmlTools.findSelfCallDoc(self, imp));
	}
}