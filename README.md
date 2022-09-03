# hlrecast
[Recast navigation](https://github.com/recastnavigation/recastnavigation) bindings for Hashlink

Reuses some work from Babylon.js's [recast bindings](https://github.com/BabylonJS/Extensions/tree/master/recastjs)

## Building
This project only supports Hashlink, and JS (except JS is broken). It uses [webIDL](https://github.com/ncannasse/webidl), and additionally emscripten for the JS port.

### Hashlink
```
haxe -lib webidl --macro recast.Generator.generateCpp()"
msbuild recast.vcxproj
```

### Javascript
Make sure you run `emsdk_env` first.
```
haxe -lib webidl --macro "recast.Generator.generateJs()"
```

## Sample
The sample uses Heaps, and is setup with lix. 
