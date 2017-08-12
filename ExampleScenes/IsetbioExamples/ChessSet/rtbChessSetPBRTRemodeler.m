function nativeScene = rtbChessSetPBRTRemodeler(parentScene,nativeScene,mappings,names,conditionValues,conditionNumber)
%%rtbChessSetPBRTRemodeler
%
% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.

% 08/12/17  dhb  Make function name in function match its filename.

%% Get condition values

numSamples = rtbGetNamedNumericValue(names, conditionValues, 'pixelSamples', []);
metadataType = rtbGetNamedValue(names,conditionValues,'metadataType',[]);

%% Choose integrator and sampler.

integrator = nativeScene.find('SurfaceIntegrator');

% Choose integrator strategy according to metadataType
if(strcmp(metadataType,'depth'))
    integrator.type = 'metadata';
    integrator.setParameter('strategy','string','depth');
elseif(strcmp(metadataType,'material'))
    integrator.type = 'metadata';
    integrator.setParameter('strategy','string','material');
elseif(strcmp(metadataType,'mesh'))
    integrator.type = 'metadata';
    integrator.setParameter('strategy','string','mesh');
elseif(strcmp(metadataType,'radiance'))
    integrator.type = 'path';
else
    Error('Cannot recognize metadata type.')
end

% If we use a metadata integrator, we should change the sampler to make it
% more efficient.
sampler = nativeScene.find('Sampler');
if(strcmp(integrator.type,'metadata'))
    
    sampler = nativeScene.find('Sampler');
    sampler.type = 'stratified';
    sampler.setParameter('jitter','bool','false')
    sampler.setParameter('xsamples','integer',1);
    sampler.setParameter('ysamples','integer',1);
    
    filter = nativeScene.find('PixelFilter');
    filter.type = 'box';
    filter.setParameter('xwidth','float',0.5);
    filter.setParameter('ywidth','float',0.5);

else
    % Change the number of samples according to the conditions
    sampler.setParameter('pixelsamples', 'integer', numSamples);
end


%% Choose a type of camera to render with

% Use a pinhole camera
camera =  nativeScene.find('Camera');
camera.type = 'pinhole';
camera.setParameter('filmdiag', 'float', 20);
camera.setParameter('filmdistance', 'float', 20);

%% Add environment light

environmentLight = MPbrtElement('LightSource','type','infinite');
environmentLight.setParameter('nsamples','integer',32);
% TODO: Fix PBRT so we can scale this.
environmentLight.setParameter('mapname','string','resources/studio007small.exr');
% environmentLight.setParameter('L','rgb',1*[1 1 1])
nativeScene.world.append(environmentLight);

%% Add lights
% 
% % Find the AreaLight mesh element
% AreaLightElement = nativeScene.world.find('Object','name','LightMaterial');
% 
% % Promote object to AreaLight
% rtbMPbrtBlessAsAreaLight(AreaLightElement,nativeScene,'L','D65.spd'); 


end