#if js
import js.lib.Int32Array;
import js.lib.Float32Array;
#end
import h3d.col.Point;
import hxd.Key;
import h3d.scene.Graphics;
import h3d.mat.MaterialSetup;
import h3d.scene.Mesh;
import h3d.mat.Texture;

#if js
@:expose
#end
class Main extends hxd.App
{
	var library: hxd.fmt.hmd.Library;

	var gDebugMesh: h3d.scene.Graphics;
	var gDebugNav: h3d.scene.Graphics;
	var interactive: h3d.scene.Interactive;

	var lastPos = new h3d.col.Point(0,0,0);

	var navMesh: recast.Native.NavMesh;

	override function init()
	{
		// scene setup
		new h3d.scene.fwd.DirLight(new h3d.Vector( 0.3, -0.4, -0.9), s3d);
		new h3d.scene.fwd.DirLight(new h3d.Vector(1, 2, -4), s3d);
		gDebugMesh = new Graphics(s3d);
		gDebugNav = new Graphics(s3d);

		gDebugNav.lineStyle(3,0x00FF00);

		// Place our world mesh
		library = hxd.Res.navtest.toHmd();
		var obj = library.makeObject();
		s3d.addChild(obj);

		interactive = new h3d.scene.Interactive(obj.getCollider(),s3d);
		interactive.onClick = function(e: hxd.Event)
		{
			gDebugNav.clear();
			var newPos = new Point(e.relX, e.relY, e.relZ + 1 );

			// Use recast to find a path from our old pos to the new one
			var start = new recast.Native.Vec3(-lastPos.x, lastPos.z, lastPos.y);
			var end = new recast.Native.Vec3(-newPos.x, newPos.z, newPos.y);
			var path = navMesh.computePath( start, end );


			start.delete();
			end.delete();

			if( path.getPointCount() == 0 )
			{
				gDebugNav.lineStyle(4,0xFF0000);
				gDebugNav.drawLine(lastPos, newPos );

				path.delete();
				lastPos = newPos;
				return;
			}

			gDebugNav.lineStyle(4,0x00FF00);
			gDebugNav.moveTo(lastPos.x, lastPos.y, lastPos.z );

			for( i in 0 ... path.getPointCount() )
			{
				var p = path.getPoint(i);
				gDebugNav.lineTo( -p.x, p.z, p.y );
			}

			path.delete();
			lastPos = newPos;

		};

		// Camera setup
		s3d.camera.target.set(0, 0, 0);
		s3d.camera.pos.set(120, 120, 40);

		s3d.camera.zNear = 1;
		s3d.camera.zFar = 100;
		new h3d.scene.CameraController(s3d).loadFromCamera();

		buildNavMesh();
	}

	function buildNavMesh()
	{
		// Ok yeah but...
		var config = new recast.Native.RcConfig();

		config.cs = 0.2;
		config.ch = 0.2;
		config.walkableSlopeAngle = 35;
		config.walkableHeight = 1;
		config.walkableClimb = 1;
		config.walkableRadius = 1;
		config.maxEdgeLen = 12;
		config.maxSimplificationError = 1.3;
		config.minRegionArea = 8;
		config.mergeRegionArea = 20;
		config.maxVertsPerPoly = 6;
		config.detailSampleDist = 6;
		config.detailSampleMaxError = 1;

		navMesh = new recast.Native.NavMesh();

		var data = library.header.geometries[0];

		var pos = library.getBuffers(data, [new hxd.fmt.hmd.Data.GeometryFormat("position", DVec3)]);

		#if js
		var positions: Float32Array = new Float32Array( data.vertexCount * 3 );
		var indexes: Int32Array = new Int32Array( data.indexCount );

		for( i in  0 ... data.vertexCount )
		{
			positions[i*3 + 0] = pos.vertexes[i * 3 + 0];
			positions[i*3 + 1] = pos.vertexes[i * 3 + 1];
			positions[i*3 + 2] = pos.vertexes[i * 3 + 2];
		}

		for( i in 0 ... data.indexCount )
		{
			indexes[i] = pos.indexes[i];
		}

		// @todo: For now, the hase WebIDL lib does not appear to support directly binding arrays.
		// So we're going to have to do it manually, and it's pretty gross. Apologies.

		var indexCount = data.indexCount;
		var positionCount = data.vertexCount;

		var indexOffset = 0;
		var positionOffset = 0;
		js.Syntax.code("
		positionOffset = recast._malloc(positionCount * 16);
		recast.HEAPF32.set(positions,positionOffset / 4);
		indexOffset = recast._malloc(indexCount * 4);
		recast.HEAPU32.set(indexes,indexOffset / 4);");

		navMesh.build(cast positionOffset, positionCount, cast indexOffset,  indexCount, config);
		#else
		var positions: hl.BytesAccess<Single> = new hl.Bytes( data.vertexCount * 3 );
		var indexes: hl.BytesAccess<Int> = new hl.Bytes( data.indexCount );

		for( i in  0 ... data.vertexCount )
		{
			positions.set(i*3 + 0, pos.vertexes[i * 3 + 0]);
			positions.set(i*3 + 1, pos.vertexes[i * 3 + 1]);
			positions.set(i*3 + 2, pos.vertexes[i * 3 + 2]);
		}

		for( i in 0 ... data.indexCount )
		{
			indexes.set(i, pos.indexes[i]);
		}

		navMesh.build(cast positions, data.vertexCount, cast indexes,  data.indexCount, config);
		#end

		// Draw bounds
		var debugMesh = navMesh.getDebugNavMesh();
		gDebugMesh.lineStyle(1, 0x002288);

		for( i in 0 ... debugMesh.getTriangleCount() )
		{
			var triangle = debugMesh.getTriangle( i );
			var p1 = triangle.getPoint(0);
			var p2 = triangle.getPoint(1);
			var p3 = triangle.getPoint(2);

			// Re-oriente mesh for z-up
			gDebugMesh.moveTo( -p1.x, p1.z, p1.y );

			gDebugMesh.lineTo( -p2.x, p2.z, p2.y );
			gDebugMesh.lineTo( -p3.x, p3.z, p3.y );
			gDebugMesh.lineTo( -p1.x, p1.z, p1.y );

		}


	}

	override function update(dt:Float) {
		#if sys
		if( Key.isPressed( Key.F5  ) )
			hxd.System.exit();
		#end
	}

	static function main() {
		#if hl
		hxd.Res.initLocal();
		new Main();
		#else
		hxd.Res.initEmbed();
		#end

	}

}