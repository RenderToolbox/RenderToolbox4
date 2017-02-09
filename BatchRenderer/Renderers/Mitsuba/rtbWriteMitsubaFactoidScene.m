function factoidFile = rtbWriteMitsubaFactoidScene(originalFile, varargin)
% Convert the given scene to get factoids instead of ray tracing.
%
% factoidFile = rtbWriteMitsubaFactoidScene(originalFile) copies and
% modifies the given originalFile so that it will produce Mitsuba ground
% truth "factoids" instead of ray tracing data.  Returns a new Mitsuba
% scene file based on the given originalFile.
%
% The returned sceneFile woill specify a "multichannel" integrator with one
% or more nested "field" integrators.  You can pass this file to
% rtbRenderMitsubaFactoids() to obtain the factoid data.
%
% rtbWriteMitsubaFactoidScene( ... 'factoids', factoids) specify a cell
% array of ground truth factoid names to be obtained.  The default includes
% all available factoids:
%   - 'position' - absolute position of the object under each pixel
%   - 'relPosition' - camera-relative position of the object under each pixel
%   - 'distance' - distance to camera of the object under each pixel
%   - 'geoNormal' - surface normal at the surface under each pixel
%   - 'shNormal' - surface normal at the surface under each pixel, interpolated for shading
%   - 'uv' - texture mapping UV coordinates at the surface under each pixel
%   - 'albedo' - diffuse reflectance of the object under each pixel
%   - 'shapeIndex' - integer identifier for the object under each pixel
%   - 'primIndex' - integer identifier for the triangle or other primitive under each pixel
%
% rtbWriteMitsubaFactoidScene( ... 'factoidFormat', factoidFormat) specify
% a mitsuba pixel format to use for formatting the output, like 'rgb' or
% 'spectrum'.  The default is 'rgb'.
%
% rtbWriteMitsubaFactoidScene( ... 'singleSampling', singleSampling)
% whether or not to do a simplified rendering with one sample per pixel and
% a narrow "box" reconstruction filder.  This is useful for labeling
% factoids like shapeIndex, where it doesn't make sense to average across
% multiple ray samples.  The default is true, do a simplified rendering.
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('originalFile', @ischar);
parser.addParameter('factoidFile', '', @ischar);
parser.addParameter('factoids', ...
    {'position', 'relPosition', 'distance', 'geoNormal', 'shNormal', ...
    'uv', 'albedo', 'shapeIndex', 'primIndex'}, ...
    @iscellstr);
parser.addParameter('factoidFormat', 'rgb', @ischar);
parser.addParameter('singleSampling', true, @islogical);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(originalFile, varargin{:});
originalFile = parser.Results.originalFile;
factoidFile = parser.Results.factoidFile;
factoids = parser.Results.factoids;
factoidFormat = parser.Results.factoidFormat;
singleSampling = parser.Results.singleSampling;
hints = rtbDefaultHints(parser.Results.hints);

% look carefully for the input file
workingFolder = rtbWorkingFolder('hints', hints);
fileInfo = rtbResolveFilePath(originalFile, workingFolder);
originalFile = fileInfo.absolutePath;

% default output like the input
if isempty(factoidFile)
    [factoidPath, factoidBase] = fileparts(originalFile);
    factoidFile = fullfile(factoidPath, [factoidBase '-factoids.xml']);
end


%% Read the in the scene xml document.
sceneDocument = xml2struct(originalFile);


%% Replace the integrator for multiple "fields".

% "multichannel" integrator to hold several "fields"
integrator.Attributes.id = 'integrator';
integrator.Attributes.type = 'multichannel';
sceneDocument.scene.integrator = integrator;

% nested "field" for each factoid
nFactoids = numel(factoids);
fieldIntegrators = cell(1, nFactoids);
for ff = 1:nFactoids
    factoidName = factoids{ff};
    
    fieldIntegrator = struct();
    fieldIntegrator.Attributes.name = factoidName;
    fieldIntegrator.Attributes.type = 'field';
    fieldIntegrator.string.Attributes.name = 'field';
    fieldIntegrator.string.Attributes.value = factoidName;
    
    fieldIntegrators{ff} = fieldIntegrator;
end
sceneDocument.scene.integrator.integrator = fieldIntegrators;


%% Replace the film for exr and factoid formats.
sceneDocument.scene.sensor.film.Attributes.type = 'hdrfilm';
filmStrings = cell(1, 4);
filmStrings{1}.Attributes.name = 'componentFormat';
filmStrings{1}.Attributes.value = 'float16';
filmStrings{2}.Attributes.name = 'fileFormat';
filmStrings{2}.Attributes.value = 'openexr';

[formatCell{1:nFactoids}] = deal(factoidFormat);
formatList = sprintf('%s, ', formatCell{:});
filmStrings{3}.Attributes.name = 'pixelFormat';
filmStrings{3}.Attributes.value = formatList(1:end-2);

nameList = sprintf('%s, ', factoids{:});
filmStrings{4}.Attributes.name = 'channelNames';
filmStrings{4}.Attributes.value = nameList(1:end-2);

sceneDocument.scene.sensor.film.string = filmStrings;


%% Replace the filter and sampler for simplified rendering?
if singleSampling
    sampler.Attributes.id = 'sampler';
    sampler.Attributes.type = 'ldsampler';
    sampler.integer.Attributes.name = 'sampleCount';
    sampler.integer.Attributes.value = 1;
    sceneDocument.scene.sensor.sampler = sampler;
    
    rfilter.Attributes.id = 'rfilter';
    rfilter.Attributes.type = 'box';
    rfilter.float.Attributes.name = 'radius';
    rfilter.float.Attributes.value= 0.5;
    sceneDocument.scene.sensor.film.rfilter = rfilter;
end


%% Write back the scene document.
struct2xml(sceneDocument, factoidFile);
