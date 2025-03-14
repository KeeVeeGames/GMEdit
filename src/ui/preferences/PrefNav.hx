package ui.preferences;
import tools.NativeString;
import electron.Electron;
import electron.FileWrap;
import js.html.Element;
import js.html.InputElement;
import ui.Preferences.*;
import gml.GmlAPI;
import gml.Project;
import ui.RecentProjects;
import ui.preferences.PrefData;
using tools.HtmlTools;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefNav {
	static function buildTreeview(out:Element) {
		out = addGroup(out, "Treeview");
		out.dataset.outlineViewLabel = "Treeview";
		addCheckbox(out, "Open assets with single click", current.singleClickOpen, function(z) {
			current.singleClickOpen = z;
			save();
			Project.current.reload();
		}).title = "Allows to open treeview items with single click";
		//
		addCheckbox(out, "Show asset thumbnails", current.assetThumbs, function(z) {
			current.assetThumbs = z;
			save();
			Project.current.reload();
		}).title = (
			"Loads and displays the assigned sprites as object thumbnails in resource tree."
			+ " Disabling this can improve memory use."
		);
		//
		addCheckbox(out, "Clear asset thumbnails on refresh", current.clearAssetThumbsOnRefresh, function(z) {
			current.clearAssetThumbsOnRefresh = z;
			save();
		}).title = (
			"Reloads asset thumbnails when refreshing (Ctrl+R) a project."
			+ " Disabling this can improve refresh speeds"
			+ " at cost of not reflecting any potential changes to sprites"
		);
		//
		addIntInput(out, "Batch size for indexing/project search", current.assetIndexBatchSize, function(n) {
			current.assetIndexBatchSize = n;
			save();
		}).title = (
			"Higher values speed up loading/searching times on big projects, but going too high"
			+ " may cause load/search errors due to running out of file descriptors."
			+ " Note that this is measured in assets rather than files due to implementation details."
		);
		//
		var assetOrder23 = [
			"Custom order (as authored)",
			"Ascending (A-Z)",
			"Descdning (Z-A)",
		];
		addDropdown(out, "GMS2.3 asset order", assetOrder23[current.assetOrder23], assetOrder23, function(s:String) {
			current.assetOrder23 = assetOrder23.indexOf(s);
			save();
			Project.current.reload();
		});
		//
		return out;
	}
	static function buildChromeTabs(out:Element) {
		PrefNavTabs.build(out);
	}
	static function buildCaching(out:Element) {
		var g = addGroup(out, "Asset caching");
		addWiki(g, "https://github.com/YellowAfterlife/GMEdit/wiki/preferences#asset-caching");
		//
		var cbIndex:InputElement = null;
		addCheckbox(g, "Cache text files in memory after load",
			current.assetCache,
		function(v) {
			current.assetCache = v;
			if (cbIndex != null) cbIndex.disabled = !v;
			save();
		});
		//
		var ctrIndex = addCheckbox(g, "And cache small text files in a combined \"index\" file on disk",
			current.diskAssetCache.enabled, andSave(v -> current.diskAssetCache.enabled = v)
		);
		cbIndex = ctrIndex.querySelectorAuto("input");
		if (cbIndex != null) cbIndex.disabled = !current.assetCache;
		//
		addIntInput(g, "Maximum size per item (in characters)",
			current.diskAssetCache.maxSizePerItem,
			andSave(v -> current.diskAssetCache.maxSizePerItem = v)
		);
		addIntInput(g, "Minimum item count in \"index\" file",
			current.diskAssetCache.minItemCount,
			andSave(v -> current.diskAssetCache.minItemCount = v)
		);
		addFloatInput(g, "Index update threshold (in %)",
			current.diskAssetCache.cacheUpdateThreshold,
			andSave(v -> current.diskAssetCache.cacheUpdateThreshold = v)
		);
		addInput(g, "File extensions (e.g. `gml; yy`)",
			current.diskAssetCache.fileExtensions.join("; "),
			function(str) {
				var vals = str.split(";").map(v -> v.trimBoth().toLowerCase());
				current.diskAssetCache.fileExtensions = vals;
			}
		);
	}
	static function buildFiles(out:Element) {
		out = addGroup(out, "File handling");
		out.dataset.outlineViewLabel = "";
		var eventOrder = [
			"As authored",
			"By event type",
		];
		addDropdown(out, "GMS2 object event order", eventOrder[current.eventOrder], eventOrder, function(s:String) {
			current.eventOrder = eventOrder.indexOf(s);
			save();
		});
		//
		var apiOrder = [
			"As authored",
			"Alphabetical",
		];
		addDropdown(out, '"Show extension API" entry order',
			apiOrder[current.extensionAPIOrder], apiOrder,
		function(s:String) {
			current.extensionAPIOrder = apiOrder.indexOf(s);
			save();
		});
		//
		addCheckbox(out, "Avoid changing YY files where possible", current.avoidYyChanges, function(z) {
			current.avoidYyChanges = z;
			save();
		}).title = "Does not overwrite files if changes only affect whitespace/field order.";
		//
		var fileChangeActions = [
			"Do nothing",
			"Ask what to do",
			"Reload unless conflicting",
		];
		addDropdown(out, "If the source file changes", fileChangeActions[current.fileChangeAction], fileChangeActions, function(v) {
			current.fileChangeAction = fileChangeActions.indexOf(v); save();
		});
		addCheckbox(out, "Close associated tab(s) when deleting a resource in GMEdit", current.closeTabsOnFileDeletion, function(v) {
			current.closeTabsOnFileDeletion = v; save();
		});
		//
		buildCaching(out);
		//
		return out;
	}
	static function buildRecent(out:Element) {
		out = addGroup(out, "Recent files & sessions");
		out.dataset.outlineViewLabel = "";
		addFloatInput(out, "Keep file sessions for (days):", current.fileSessionTime, function(v) {
			current.fileSessionTime = v; save();
		});
		#if !lwedit
		addFloatInput(out, "Keep project sessions for (days):", current.projectSessionTime, function(v) {
			current.projectSessionTime = v; save();
		});
		addIntInput(out, "Max recent project count:", current.recentProjectCount, function(v) {
			current.recentProjectCount = v; save();
		});
		
		addButton(out, "Clear recent projects", function() {
			RecentProjects.clear();
		});
		#end
		return out;
	}
	static function buildMisc(out:Element) {
		out = addGroup(out, "Misc.");
		out.dataset.outlineViewLabel = "Misc.";
		addCheckbox(out, "Show taskbar overlays", current.taskbarOverlays, function(z) {
			current.taskbarOverlays = z;
			save();
			Project.current.reload();
		}).title = ("Shows GM version icon"
			+ " (or `<project path>.taskbar-overlay.png`, if available)"
			+ " over the GMEdit icon (Windows-only?)"
		);
		//
		if (Electron != null) {
			addInput(out, "Gmk-Splitter path (for converting GM≤8.1 projects)", current.gmkSplitPath, function(v) {
				current.gmkSplitPath = v; save();
			});
			addInput(out, "GM≤8.1 extension directory", current.gmkExtensionFolder ?? "", function(v) {
				current.gmkExtensionFolder = v; save();
			});
		}
	}
	static function buildLookup(out:Element) {
		out = addGroup(out, "Global lookup (default: Ctrl+T)");
		out.dataset.outlineViewLabel = "Global lookup";
		var compMatchModes = PrefMatchMode.names;
		var el:Element;
		
		el = addDropdown(out, "Auto-completion mode", compMatchModes[current.globalLookup.matchMode], compMatchModes, function(s) {
			current.globalLookup.matchMode = compMatchModes.indexOf(s);
			save();
		});
		
		el = addIntInput(out, "Maximum item count", current.globalLookup.maxCount, function(i) {
			if (i < 1) i = 1;
			current.globalLookup.maxCount = i;
			save();
		});
		
		el = addIntInput(out, "Initial width", current.globalLookup.initialWidth, function(i) {
			if (i < 160) i = 1;
			current.globalLookup.initialWidth = i;
			save();
		});
		
		el = addIntInput(out, "Initial height", current.globalLookup.initialHeight, function(i) {
			if (i < 160) i = 1;
			current.globalLookup.initialHeight = i;
			save();
		});
		
		el = addGroup(out, "Default filters"); {
			el.classList.add("collapsed");
			el.style.display = "flex";
			el.style.flexDirection = "column";
			var tmp = Main.document.createDivElement();
			el.appendChild(tmp);
			tmp.outerHTML = GlobalLookup.checkboxHTML;
			var opts = current.globalLookup.initialFilters;
			for (cb in el.querySelectorAllAuto("input", InputElement)) {
				var opt = opts[cb.name];
				if (opt != null) cb.checked = opt;
				cb.addEventListener("change", function(_) {
					current.globalLookup.initialFilters[cb.name] = cb.checked;
					save();
				});
			}
		}
	}
	public static function build(out:Element) {
		out = addGroup(out, "Navigation");
		out.id = "pref-navigation";
		var el:Element;
		//
		#if !lwedit
		buildTreeview(out);
		#end
		buildLookup(out);
		#if !lwedit
		buildFiles(out);
		#end
		buildRecent(out);
		buildChromeTabs(out);
		buildMisc(out);
	}
}
