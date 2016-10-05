RenderToolbox4
==============
RenderToolbox4 is a Matlab toolbox for working with 3D scenes and physically-based renderers.

![dragon model in 4 materials](https://raw.githubusercontent.com/RenderToolbox3/RenderToolbox4/gh-pages/ExampleScenes/Dragon/DragonMaterials%20(PBRT).png)

For more information, please see the [wiki](https://github.com/RenderToolbox3/RenderToolbox4/wiki).

# Installation
RenderToolbox requires [Matlab](https://www.mathworks.com/products/matlab/), a few native system dependencies, and some Matlab toolboxes.

We test RenderToolbox with OS X and Linux.  Windows should be possible, but we haven't tested it.

## System Dependencies
RenderToolbox has a few native system dependencies.

### Assimp
RenderToolbox requires [Assimp](http://www.assimp.org/) for reading and writing 3D scene files.  v3.3.1 or greater is expected to work.

On OS X, this should be easy with [Homebrew](http://brew.sh/index.html).
```
brew install assimp
```

On Linux, you should build Assimp v3.3.1 from source.  This is usually painless with [cmake](https://cmake.org/).
```
git clone https://github.com/assimp/assimp.git
cd assimp
git checkout v3.3.1
cmake CMakeLists.txt -G 'Unix Makefiles'
make
sudo make install
ldconfig
```

### OpenEXR
RenderToolbox requires [OpenEXR](http://www.openexr.com/) for reading multi-spectral image files.  Version 2.2.0 is expected to work.

On OS X, this should be easy with [Homebrew](http://brew.sh/index.html).
```
brew install openexr
```

On Linux, this should be easy with your package manager.  For example, on Ubuntu:
```
sudo apt-get update
sudo apt-get install openexr
```

### Docker
RenderToolbox uses [Docker](https://github.com/RenderToolbox3/RenderToolbox4/wiki/Docker) to distribute pre-built renderers and other tools.  Here's where you can [Get Docker](https://www.docker.com/products/overview) for Linux, OS X, or Windows.

## Toolboxes
The best way to get RenderToolbox and other required toolboxes is to use the [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox).

If you have the ToolboxToolbox, then getting RenderToolbox becomes a one-liner:
```
tbUse('RenderToolbox4');
```

This will download necessary Matlab toolboxes and Docker images for RenderToolbox.  The first time through, this may take a while.

## Preferences
The ToolboxToolbox will also create a configuration script which you can edit with local preferences.  This script will be named `RenderToolbox4.m`.  The default folder would be in your Matlab [userpath](https://www.mathworks.com/help/matlab/ref/userpath.html).  For example: 
```
~/Documents/MATLAB/RenderToolbox4.m
```

Here are some preferences you might wish to edit in this script:
 - which Docker images to use for rendering -- edit [here](https://github.com/RenderToolbox3/RenderToolbox4/blob/master/rtbLocalConfigTemplate.m#L47) for Mitsuba, [here](https://github.com/RenderToolbox3/RenderToolbox4/blob/master/rtbLocalConfigTemplate.m#L76) for PBRT
 - where to store output files: edit [here](https://github.com/RenderToolbox3/RenderToolbox4/blob/master/rtbLocalConfigTemplate.m#L27)
 - where to find local renderer executables, in case Docker is not available: edit [here](https://github.com/RenderToolbox3/RenderToolbox4/blob/master/rtbLocalConfigTemplate.m#L50) for Mitsuba, [here](https://github.com/RenderToolbox3/RenderToolbox4/blob/master/rtbLocalConfigTemplate.m#L79) for PBRT

Next time you do `tbUse('RenderToolbox4')` your custom preferences will be set up.

## Testing
To test that RenderToolbox is installed correctly, you can run
```
rtbTestInstallation();
```

This should render 4 scenes, each with PBRT and Mitsuba.  The result should look like this:
```
4 scenes succeeded.

1 rtbMakeCoordinatesTest.m
2 rtbMakeDragon.m
3 rtbMakeMaterialSphereBumps.m
4 rtbMakeMaterialSphereRemodeled.m

0 scenes failed.

Elapsed time is 133.631781 seconds.

Your RenderToolbox4 installation seems to be working!
```

# About
RenderToolbox4 is released under the MIT License.  Please see LICENSE.txt for details.

RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
 - [About Us](https://github.com/RenderToolbox3/RenderToolbox4/wiki/wiki/About-Us)
 - [Join Us](https://github.com/RenderToolbox3/RenderToolbox4/wiki/wiki/Join-Us)
 
![dragon model in 24 ColorChecker colors](https://raw.githubusercontent.com/RenderToolbox3/RenderToolbox4/gh-pages/ExampleScenes/Dragon/DragonColorChecker%20%28PBRT%29.png)

