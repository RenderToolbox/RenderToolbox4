function nativeScene = rtbCrytekPBRTRemodeler(parentScene,nativeScene,mappings,names,conditionValues,conditionNumber)

% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.

%% Get condition values

numSamples = rtbGetNamedNumericValue(names, conditionValues, 'pixelSamples', []);
% TEMP
lightSpectrum = conditionValues(end);

%% Choose integrator and sampler.

% Change surface integrator to path.
integrator = nativeScene.find('SurfaceIntegrator');
integrator.type = 'path';

% Change the number of samples
sampler = nativeScene.find('Sampler');
sampler.setParameter('pixelsamples', 'integer', numSamples);

%% Choose a type of camera to render with

camera =  nativeScene.find('Camera');
camera.type = 'pinhole';
camera.setParameter('filmdiag', 'float', 20);
camera.setParameter('filmdistance', 'float', 20);
    
%% Promote the area light mesh into an actual area light. 
% Assign appropriate spectrum based on the conditionValues

lightSpectrumName = lightSpectrum;

% TODO: Why are meshes sometimes named by their material instead of their
% actual name? (e.g. LightMaterial is the AreaLight's material, but the
% mesh is called AreaLight...)

% Find the AreaLight mesh element
AreaLightElement = nativeScene.world.find('Object','name','LightMaterial');

% Promote object to AreaLight
rtbMPbrtBlessAsAreaLight(AreaLightElement,nativeScene,'L',lightSpectrumName); 

end