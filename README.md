RenderToolbox4
==============
RenderToolbox4 is a Matlab toolbox for working with 3D scenes and physically-based renderers.  For more in formation, please see the [wiki](https://github.com/RenderToolbox3/RenderToolbox4/wiki).

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
RenderToolbox uses [[Docker]] to distribute pre-built renderers and other tools.  Docker is available for Linux, OS X, and Windows.  [Get Docker!](https://www.docker.com/products/overview).

## Toolboxes
The best way to get the Matlab toolboxes is to use the [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox).

If you have the ToolboxToolbox, then getting RenderToolbox becomes a one-liner:
```
tbUse('RenderToolbox4');
```

# About
RenderToolbox4 is released under the MIT License.  Please see LICENSE.txt for details.

RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
 - [About Us](https://github.com/RenderToolbox3/RenderToolbox4/wiki/wiki/About-Us)
 - [Join Us](https://github.com/RenderToolbox3/RenderToolbox4/wiki/wiki/Join-Us)
