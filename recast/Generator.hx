package recast;

#if eval
class Generator {

	static var INCLUDE = '
#ifdef _WIN32
#pragma warning(disable:4305)
#pragma warning(disable:4244)
#pragma warning(disable:4316)
#undef min
#undef max
#endif

#include "recastjs.h"
#include "Recast.h"
#include "DetourNavMesh.h"
#include "DetourCommon.h"
#include "DetourNavMeshBuilder.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"
#include "ChunkyTriMesh.h"


';

	static var options = { idlFile : "recast/recast.idl", nativeLib : "recast", outputDir : "src", includeCode : INCLUDE, autoGC : true };

	public static function generateCpp() {
		webidl.Generate.generateCpp(options);
	}

	public static function getFiles() {
		var prj = new haxe.xml.Access(Xml.parse(sys.io.File.getContent("recast.vcxproj.filters")).firstElement());
		var sources = [];
		for( i in prj.elements )
			if( i.name == "ItemGroup" )
				for( f in i.elements ) {
					if( f.name != "ClCompile" ) continue;
					var fname = f.att.Include.split("\\").join("/");

					sources.push(fname);
				}
		return sources;
	}

	public static function generateJs() {
		// ammo.js params
		var debug = true;
		var defines = debug ? [] : ["NO_EXIT_RUNTIME=1", "NO_FILESYSTEM=1", "AGGRESSIVE_VARIABLE_ELIMINATION=1", "ELIMINATE_DUPLICATE_FUNCTIONS=1", "NO_DYNAMIC_EXECUTION=1"];
		var params = ["-O"+(debug?0:3), "-g3",  "--llvm-lto", "1",
				"-I", "src/",
				"-I", "recastnavigation/Detour/Include",
				"-I", "recastnavigation/DetourCrowd/Include",
				"-I", "recastnavigation/DetourTileCache/Include",
				"-I", "recastnavigation/Recast/Include",
				"-I", "recastnavigation/RecastDemo/Include",

				"-Wno-unused-command-line-argument"];
		for( d in defines ) {
			params.push("-s");
			params.push(d);
		}
		// in JS the output dir is already added elsewhere, remove the double include
		options.outputDir = ".";
		webidl.Generate.generateJs(options, getFiles(), params);
	}

}
#end