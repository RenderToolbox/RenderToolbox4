classdef RtbAssimpMitsubaConverter < RtbConverter
    %% Implementation for rendering converting mexximp to Mitsuba.
    %
    
    properties
        % RenderToolbox options struct, see rtbDefaultHints()
        hints;
        
        % default material for mexximp conversion
        material;
        
        % material parameter to receive diffuse reflectance data
        diffuseParameter;
        
        % material parameter to receive specular reflectance data
        specularParameter;
        
        % where to write output files, like scene or geometry
        outputFolder;
        
        % subfolder for geometry within the workingFolder
        meshSubfolder;
        
        % whether to overwrite/update existing mesh files
        rewriteMeshData;
    end
    
    methods (Static)
        function material = defaultMaterial()
            material = MMitsubaElement('', 'bsdf', 'diffuse');
            material.append(MMitsubaProperty.withValue('reflectance', 'spectrum', '300:1 800:1'));
        end
    end
    
    methods
        
        function obj = RtbAssimpMitsubaConverter(hints)
            obj.hints = rtbDefaultHints(hints);
            obj.material = RtbAssimpMitsubaConverter.defaultMaterial();
            obj.diffuseParameter = 'reflectance';
            obj.specularParameter = '';
            obj.outputFolder = rtbWorkingFolder( ...
                'folderName', 'scenes', ...
                'rendererSpecific', true, ...
                'hints', obj.hints);
            obj.meshSubfolder = 'mitsuba-geometry';
            obj.rewriteMeshData = true;
        end
        
        function defaultMappings = loadDefaultMappings(obj, varargin)
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('imageWidth', 320, @isnumeric);
            parser.addParameter('imageHeight', 240, @isnumeric);
            parser.parse(varargin{:});
            imageWidth = parser.Results.imageWidth;
            imageHeight = parser.Results.imageHeight;
            
            mm = 1;
            defaultMappings{mm}.name = 'integrator';
            defaultMappings{mm}.broadType = 'integrator';
            defaultMappings{mm}.index = [];
            defaultMappings{mm}.specificType = 'direct';
            defaultMappings{mm}.operation = 'create';
            defaultMappings{mm}.destination = 'Mitsuba';
            defaultMappings{mm}.properties(1).name = 'shadingSamples';
            defaultMappings{mm}.properties(1).valueType = 'integer';
            defaultMappings{mm}.properties(1).value = 32;
            
            mm = mm + 1;
            defaultMappings{mm}.name = 'sampler';
            defaultMappings{mm}.broadType = 'sampler';
            defaultMappings{mm}.index = [];
            defaultMappings{mm}.specificType = 'ldsampler';
            defaultMappings{mm}.operation = 'update';
            defaultMappings{mm}.destination = 'Mitsuba';
            defaultMappings{mm}.properties(1).name = 'sampleCount';
            defaultMappings{mm}.properties(1).valueType = 'integer';
            defaultMappings{mm}.properties(1).value = 8;
            
            mm = mm + 1;
            defaultMappings{mm}.name = 'rfilter';
            defaultMappings{mm}.broadType = 'rfilter';
            defaultMappings{mm}.index = [];
            defaultMappings{mm}.specificType = 'gaussian';
            defaultMappings{mm}.operation = 'update';
            defaultMappings{mm}.destination = 'Mitsuba';
            defaultMappings{mm}.properties(1).name = 'stddev';
            defaultMappings{mm}.properties(1).valueType = 'float';
            defaultMappings{mm}.properties(1).value = 0.5;
            
            mm = mm + 1;
            defaultMappings{mm}.name = 'film';
            defaultMappings{mm}.broadType = 'film';
            defaultMappings{mm}.index = [];
            defaultMappings{mm}.specificType = 'hdrfilm';
            defaultMappings{mm}.operation = 'update';
            defaultMappings{mm}.destination = 'Mitsuba';
            defaultMappings{mm}.properties(1).name = 'width';
            defaultMappings{mm}.properties(1).valueType = 'integer';
            defaultMappings{mm}.properties(1).value = imageWidth;
            defaultMappings{mm}.properties(2).name = 'height';
            defaultMappings{mm}.properties(2).valueType = 'integer';
            defaultMappings{mm}.properties(2).value = imageHeight;
            defaultMappings{mm}.properties(3).name = 'banner';
            defaultMappings{mm}.properties(3).valueType = 'boolean';
            defaultMappings{mm}.properties(3).value = 'false';
            defaultMappings{mm}.properties(4).name = 'componentFormat';
            defaultMappings{mm}.properties(4).valueType = 'string';
            defaultMappings{mm}.properties(4).value = 'float16';
            defaultMappings{mm}.properties(5).name = 'fileFormat';
            defaultMappings{mm}.properties(5).valueType = 'string';
            defaultMappings{mm}.properties(5).value = 'openexr';
            defaultMappings{mm}.properties(6).name = 'pixelFormat';
            defaultMappings{mm}.properties(6).valueType = 'string';
            defaultMappings{mm}.properties(6).value = 'spectrum';
            
            mm = mm + 1;
            defaultMappings{mm}.name = '';
            defaultMappings{mm}.broadType = 'sensor';
            defaultMappings{mm}.index = [];
            defaultMappings{mm}.operation = 'update';
            defaultMappings{mm}.destination = 'Mitsuba';
            defaultMappings{mm}.properties(1).name = 'nearClip';
            defaultMappings{mm}.properties(1).valueType = 'float';
            defaultMappings{mm}.properties(1).value = 0.1;
            defaultMappings{mm}.properties(2).name = 'farClip';
            defaultMappings{mm}.properties(2).valueType = 'float';
            defaultMappings{mm}.properties(2).value = 1e6;
        end
        
        function nativeScene = startConversion(obj, parentScene, mappings, names, conditionValues, conditionNumber)
            nativeScene = mMitsubaImportMexximp(parentScene, ...
                'materialDefault', obj.material, ...
                'materialDiffuseParameter', obj.diffuseParameter, ...
                'materialSpecularParameter', obj.specularParameter, ...
                'workingFolder', obj.outputFolder, ...
                'meshSubfolder', obj.meshSubfolder, ...
                'rewriteMeshData', obj.rewriteMeshData);
        end
        
        function nativeScene = applyMappings(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
            imageWidth = rtbGetNamedValue(names, conditionValues, 'groupName', '');
            if isempty(imageWidth)
                groupMappings = mappings;
            else
                isAnyGroup = strcmp('', {mappings.group});
                isInGroup = strcmp(imageWidth, {mappings.group});
                groupMappings = mappings(isAnyGroup | isInGroup);
            end
            nativeScene = rtbApplyMMitsubaMappings(nativeScene, groupMappings);
            nativeScene = rtbApplyMMitsubaGenericMappings(nativeScene, groupMappings);
            
            % update image size, if given in conditions file
            imageWidth = rtbGetNamedValue(names, conditionValues, 'imageWidth', '');
            if ~isempty(imageWidth)
                film = nativeScene.find('film');
                film.setProperty('width', 'integer', imageWidth);
            end
            imageHeight = rtbGetNamedValue(names, conditionValues, 'imageHeight', '');
            if ~isempty(imageHeight)
                film = nativeScene.find('film');
                film.setProperty('height', 'integer', imageHeight);
            end
        end
        
        % transition in-memory nativeScene to on-disk mitsubaFile
        function mitsubaFile = finishConversion(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
            imageName = rtbGetNamedValue(names, conditionValues, 'imageName', ...
                sprintf('scene-%03d', conditionNumber));
            mitsubaAbsoluteFile = fullfile(obj.outputFolder, [imageName '.xml']);
            nativeScene.printToFile(mitsubaAbsoluteFile);
            
            % return a path relative to the working folder
            mitsubaFile = rtbGetWorkingRelativePath(mitsubaAbsoluteFile, ...
                'hints', obj.hints);
        end
    end
end
