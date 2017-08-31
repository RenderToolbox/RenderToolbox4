
Isetbio Examples
==============
The examples in this folder use RenderToolbox.  If you have  a separate toolbox called [isetbio](https://github.com/isetbio/isetbio), installed, they will also bring the images into isetbio format and display them in an isetbio window.  You must have isetbio on your Matlab path for this latter feature  to work.

If you use [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox) then you can obtain RenderToolbox and isetbio and put them on your path like this:
```
% One at a time
tbUse('RenderToolbox4');
tbUse('isetbio','reset','as-is');

% Both at once
tbUse({'RenderToolbox4', 'isetbio'});
```

Otherwise, you can follow the [installation](https://github.com/isetbio/isetbio/wiki/ISETBIO%20Installation) instructions on the isetbio wiki.

It is worth a little thought about whether energy and quantal units are being handled properly on the conversion into isetbio.


