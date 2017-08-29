%% Render a chess set with different metadata parameters.
%
% We render a scene of a chess set along with some "metadata" images. There
% are four images total:
% 1. Radiance image
% 2. Depth map
% 3. Material map
% 4. Mesh object map
%
% The depth images is the distance between the camera and each object. The
% material image is an indexed image that corresponds to each unique
% material. The mesh image is an indexed image that corresponds to each
% unique mesh (object).
%
% When the metadata integrator is used in PBRT, we also output a text file
% that gives the corresponding index to material/mesh name mapping. This
% text file is placed in the "renderings" folder in the working folder,
% along with the rest of the renderer output.
%
% Note: For the "mesh index," we output its "primitive index" in PBRT.
% However, PBRT defines many things in the renderer with the same
% "primitive" class (e.g. acceleration structures, individual triangles,
% mesh objects.) Because of these two facts, these mesh indices tend to
% have very large numbers, potentially in the tens of thousands. To
% visualize I usually remap these numbers to a only the ones that actually
% show up in our list of indices. In the future, we can probably make some
% changes to give mesh objects unique indices instead of sharing the
% primitive index.
%
% WARNING: Be sure to remove the radiometric scale factor when displaying
% the metadata images. The scale factor is unnecessary (and a bit arbitrary
% to begin with) since PBRT is configured to output the metadata numbers
% directly.
%
% This example runs with PBRT, but proabably not with Mitsuba.
%
% Approximate time to render
% Size = [200x200]
% Pinhole, 1024 pixel samples
% Total time = ~300 seconds

% Trisha Lian
% 
% 08/12/17  dhb  Made isetbio stuff conditional on isetbio being installed.
%                Write out a png of the image in any case.
%                Some cosmetic changes.

%% Initialize
%
% If you want to use isetbio and have TbTb installed, but not isetbio, type:
%    tbUse('isetbio','reset','as-is');
clear; close all;

%% Choose batch renderer options.
hints.imageWidth = 200;
hints.imageHeight = 200;
hints.recipeName = 'ChessSet';
hints.renderer = 'PBRT';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% This function modifies general scene paraemters
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbChessSetMexximpRemodeler;

% This function modifies PBRT specific parameters
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @rtbChessSetPBRTRemodeler;

% Change the docker container to our version of PBRT-spectral
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';
resourceFolder = rtbWorkingFolder( ...
    'folderName', 'resources',...
    'hints', hints);

%% Load scene

% When exporting as an OBJ Blender, we must keep the coordinate system
% consistent. Right now I always export with YForward/ZUp and a scaling
% factor of 1000 (to convert to mm) - if the scene was original in meters.
% Nonetheless, there seems to still be a right/left flip in the images
% right now.

% The following scenefile must be a full path.
sceneFile = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'ChessSet', 'Data', 'ChessSetNoAreaLight.obj');
[scene, elements] = mexximpCleanImport(sceneFile,...
    'flipUVs',true,...
    'imagemagicImage','hblasins/imagemagic-docker',...
    'toReplace',{'jpg','tiff'},...
    'targetFormat','exr', ...
    'workingFolder', resourceFolder);

% Add a camera
scene = mexximpCentralizeCamera(scene);

% copy environment map over to main recipe folder
envMapPath = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'ChessSet', 'Data', 'studio007small.exr');
copyfile(envMapPath, resourceFolder);

%% Write conditions and generate scene files

% We will render four images.
metadataType = {'depth','material','mesh','radiance'};

nConditions = length(metadataType);
pixelSamples = ones(1,nConditions).*1024;

% Place all condition variables in a giant cell matrix
names = {'pixelSamples','metadataType'};
values = cell(nConditions, numel(names));
values(:,1) = num2cell(pixelSamples,1);
values(:,2) = metadataType;

% Write the parameters in a conditions file.
conditionsFile = 'ChessSetConditions.txt';
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, names, values);

% Make the PBRT scene file.
nativeSceneFiles = rtbMakeSceneFiles(scene,'hints', hints,'conditionsFile',conditionsPath);

%% Render!
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

%% Images for display
%
% The different rendered images come with different scales,
% so a montage doesn't work very well.  This just produces
% an output image for the 4th one, which is the nice rendered
% chess set.
toneMapFactor = 10;
isScale = true;
[SRGBMontage, XYZMontage] = ...
    rtbMakeMontage({radianceDataFiles{4}}, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));

%% Display as an isetbio optical image, if isetbio is available
if (exist('ieInit','file'))
    
    ieInit;
    renderingsFolder = rtbWorkingFolder( ...
        'folderName', 'renderings',...
        'hints', hints);
    
    % Load in rendered data
    for i = 1:nConditions
        
        imageData = load(radianceDataFiles{i});
        
        % Get rid of the radiometric scale factor
        % If we don't do this, it will interfere with the metadata output,
        % since those values do not need to be scaled.
        photons = imageData.multispectralImage./imageData.radiometricScaleFactor;
        
        % Name the OI according to which metadata we rendered
        oiName = sprintf('%s_%s',hints.recipeName,metadataType{i});
        
        % We will display each image differently depending on what type of data
        % it contains.
        if(strcmp(metadataType{i},'radiance'))
            
            %%% ---Radiance Image--- %%%
            
            % Create an oi
            oi = oiCreate;
            oi = initDefaultSpectrum(oi);
            oi = oiSet(oi, 'photons', single(photons).*imageData.radiometricScaleFactor);
            oi = oiSet(oi,'name',oiName);
            
            % Show the oi
            vcAddAndSelectObject(oi);
            
            % Save oi
            save(fullfile(renderingsFolder,oiName),'oi');
            
            % Save an RGB image
            rgb = oiGet(oi,'rgb');
            imwrite(rgb,sprintf('%s.png',oiName),'png');
            
        elseif(strcmp(metadataType{i},'depth'))
            
            %%% ---Depth Image--- %%%
            
            depthMap = photons(:,:,1);
            fig1 = imagesc(depthMap); colorbar; colormap(flipud(gray));
            axis image; axis off;
            title('Depth Map')
            saveas(fig1,oiName,'png')
            
        elseif(strcmp(metadataType{i},'material'))
            
            %%% ---Material Image--- %%%
            
            materialData = photons(:,:,1);
            fig2 = imagesc(materialData); colormap default;
            axis image; axis off;
            title('Material Index')
            saveas(fig2,oiName,'png')
            
        elseif(strcmp(metadataType{i},'mesh'))
            
            %%% ---Mesh Image--- %%%
            
            % Let's remap the mesh image indicides to be more easily viewed.
            % (See note on the top of this script).
            
            % This, however, means it will not correspond to the metadata text
            % file output for the mesh. One should use the actual meshData mat
            % for that.
            
            meshData = photons(:,:,1);
            uniqueValues = unique(meshData(:));
            remap = 1:length(uniqueValues);
            for j = 1:length(uniqueValues)
                curI = (meshData == uniqueValues(j));
                meshData(curI) = remap(j);
            end
            fig3 = imagesc(meshData);colormap default;
            axis image; axis off;
            title('Mesh Index')
            saveas(fig3,oiName,'png')
            
        else
        end
        
    end
    oiWindow;
end
