function [ camera ] = rtbCamerasInit( varargin )
% Generate an array of cameras with various parameters for rendering
%
% Used in conjunction with object placement for multiple scenes.  
%
% See also:  s_cloudExample.m
%
% HB SCIEN STANFORD< 2017

%%
p = inputParser;
p.addOptional('type',{'pinhole'});
p.addOptional('lens',{'dgauss.22deg.6.0mm'});
p.addOptional('mode',{'radiance'});
p.addOptional('pixelSamples',128);
p.addOptional('distance',10);
p.addOptional('orientation',0);
p.addOptional('height',-1.5);
p.addOptional('PTR',{[0,0,0]});
p.addOptional('defocus',0);
p.addOptional('diffraction',{'false'});
p.addOptional('chromaticAberration',{'false'});
p.addOptional('fNumber',2.8);
p.addOptional('filmDiagonal',1/6.4*25.4);
p.addOptional('microlens',{[0,0]});
p.addOptional('lookAtObject',1);

p.parse(varargin{:});
inputs = p.Results;

%% Checks
assert(length(inputs.type)==length(inputs.lens) || length(inputs.type)==1 || length(inputs.lens)==1);
assert(length(inputs.diffraction)==length(inputs.chromaticAberration) || length(inputs.diffraction)==1 || length(inputs.chromaticAberration)==1);
assert(length(inputs.microlens)==length(inputs.lens) || length(inputs.microlens) == 1 || length(inputs.lens)==1);

%% Loop

cntr = 1;
for a=1:max([length(inputs.type), length(inputs.lens), length(inputs.microlens)])
for b=1:length(inputs.pixelSamples)
for c=1:length(inputs.distance)
for d=1:length(inputs.orientation)
for e=1:length(inputs.height)
for f=1:length(inputs.PTR)
for g=1:length(inputs.defocus)
for h=1:max([length(inputs.diffraction), length(inputs.chromaticAberration)])
for i=1:length(inputs.fNumber)
for j=1:length(inputs.filmDiagonal)
for k=1:length(inputs.mode)
    for l=1:length(inputs.lookAtObject)
    
    if length(inputs.type) == 1
        camera(cntr).type = inputs.type{1};
    else
        camera(cntr).type = inputs.type{a};
    end
    if length(inputs.lens) == 1
        camera(cntr).lens = inputs.lens{1};
    else
        camera(cntr).lens = inputs.lens{a};
    end
    if length(inputs.microlens) == 1
        camera(cntr).microlens = inputs.microlens{1};
    else
        camera(cntr).microlens = inputs.microlens{a};
    end
    camera(cntr).mode = inputs.mode{k};
    camera(cntr).pixelSamples = inputs.pixelSamples(b);
    camera(cntr).fNumber = inputs.fNumber(i);
    camera(cntr).filmDiagonal = inputs.filmDiagonal(j);
    camera(cntr).distance = inputs.distance(c);
    camera(cntr).orientation = inputs.orientation(d);
    camera(cntr).height = inputs.height(e);
    camera(cntr).PTR = inputs.PTR{f};
    camera(cntr).defocus = inputs.defocus(g);
    
    if length(inputs.diffraction) == 1
        camera(cntr).diffraction = inputs.diffraction{1};
    else
        camera(cntr).diffraction = inputs.diffraction{h};
    end
    if length(inputs.chromaticAberration) == 1
        camera(cntr).chromaticAberration = inputs.chromaticAberration{1};
    else
        camera(cntr).chromaticAberration = inputs.chromaticAberration{h};
    end
    camera(cntr).lookAtObject = inputs.lookAtObject(l);
    
    cntr = cntr+1;
    end
end
end
end
end
end
end
end
end
end
end




end

