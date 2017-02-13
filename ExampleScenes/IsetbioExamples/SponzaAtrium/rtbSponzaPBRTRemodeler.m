function nativeScene = rtbSponzaPBRTRemodeler(parentScene,nativeScene,mappings,names,conditionValues,conditionNumber)

% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.

%% Get condition values
% The condition values in this example are simple, so we don't need to use
% 'rtbGetNamedNumericValue'. For an example of that, see rtbMakeFlyThrough.

lightSpectrumName = conditionValues{1};
currentAperture = conditionValues{2};
cameraType = conditionValues{3};
numSamples = conditionValues{4};

%% Choose integrator and sampler.

% Change surface integrator to path.
integrator = nativeScene.find('SurfaceIntegrator');
integrator.type = 'path';

% Change the number of samples
sampler = nativeScene.find('Sampler');
sampler.setParameter('pixelsamples', 'integer', numSamples);

%% Choose a type of camera to render with

if(strcmp(cameraType,'realistic'))
    
    % Use a 50 mm gaussian lens The back of the atrium is around 15 meters
    % away from the current camera location. We used CISET to find the
    % optimal film position (~36 mm) to keep that in focus.

    camera =  nativeScene.find('Camera');
    camera.type = 'realisticDiffraction';
    camera.setParameter('specfile', 'string', 'dgauss.50mm.dat');
    camera.setParameter('filmdistance', 'float', 36);
    camera.setParameter('aperture_diameter','float',currentAperture);
    camera.setParameter('filmdiag','float',35);
    
elseif(strcmp(cameraType,'pinhole'))
    
    camera =  nativeScene.find('Camera');
    camera.type = 'pinhole';
    camera.setParameter('filmdiag', 'float', 20);
    camera.setParameter('filmdistance', 'float', 20);
    
else
    error('Camera type in conditions file unrecognized.')
end

% TODO: How to remove a type (e.g. removeParameter), like fov which is not
% used here?

%% Promote the area light mesh into an actual area light. 
% Assign appropriate spectrum based on the conditionValues

% Find the AreaLight mesh element
AreaLightElement = nativeScene.world.find('Object','name','1_LightMaterial');

% Promote object to AreaLight
rtbMPbrtBlessAsAreaLight(AreaLightElement,nativeScene,'L',lightSpectrumName); 

end