# hlrecast
[Recast navigation](https://github.com/recastnavigation/recastnavigation) bindings for Hashlink

<img width="266" alt="recast" src="https://user-images.githubusercontent.com/134280/188249047-8d47d6b2-05c1-4ab6-9104-74df3f5c7ae8.PNG">

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
