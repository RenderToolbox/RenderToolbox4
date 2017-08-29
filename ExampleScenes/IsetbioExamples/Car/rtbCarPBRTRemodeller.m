function [ nativeScene ] = rtbCarPBRTRemodeller( parentScene, nativeScene, mappings, names, conditionValues, conditionNumbers )
%%rtbCarPBRTRemodeller  Helper function for rtbMakeCar example.

% 08/12/17  dhb  Rename.  Add one line header comment.
%           dhb  Delete commented out code.

mode = rtbGetNamedValue(names,conditionValues,'mode',[]);
taillights = rtbGetNamedValue(names,conditionValues,'taillights',[]);
daylight = rtbGetNamedValue(names,conditionValues,'daylight',[]);

filmDiag = rtbGetNamedNumericValue(names,conditionValues,'filmDiag',[]);
filmDist = rtbGetNamedNumericValue(names,conditionValues,'filmDist',[]);
pixelSamples =  rtbGetNamedNumericValue(names,conditionValues,'pixelSamples',[]);
volumeStep = rtbGetNamedNumericValue(names,conditionValues,'volumeStep',[]);

camera = nativeScene.overall.find('Camera');
camera.type = 'pinhole';
camera.setParameter('filmdiag','float',filmDiag);
camera.setParameter('filmdistance','float',filmDist);

sampler = nativeScene.overall.find('Sampler');
sampler.setParameter('pixelsamples','integer',pixelSamples);

integrator = nativeScene.overall.find('SurfaceIntegrator');
integrator.type = 'path';

if strcmp(daylight,'on');
    distantLight = nativeScene.world.find('LightSource','name','SunLight');
    distantLight.setParameter('L','spectrum','resources/SunLight.spd');
    
    distantLight = nativeScene.world.find('LightSource','name','SunLight5');
    distantLight.setParameter('L','spectrum','resources/SunLight.spd');
end

%% Rear lights
if strcmp(taillights,'on')
    rearLightReflector = nativeScene.world.find('MakeNamedMaterial','name','lights');
    rearLightReflector.type = 'mirror';
    rearLightReflector.setParameter('Kr','rgb','1 1 1');  
    
    rearLightCover = nativeScene.world.find('MakeNamedMaterial','name','HL_glass');
    rearLightCover.type = 'glass';
    rearLightCover.setParameter('Kr','rgb','1 1 1');
    rearLightCover.setParameter('Kt','rgb','1 1 1');
    
    rearLight = nativeScene.world.find('Object','name','Material__275');
    rtbMPbrtBlessAsAreaLight(rearLight,nativeScene,'L','1e3 0 0','lType','rgb');
    
    rearLight = nativeScene.world.find('Object','name','Material__274');
    rtbMPbrtBlessAsAreaLight(rearLight,nativeScene,'L','1e3 0 0','lType','rgb');
end

switch mode
    case 'fog'
        nativeScene.overall.find('SurfaceIntegrator','remove',true);
        volumeIntegrator = MPbrtElement('VolumeIntegrator','type','single');
        volumeIntegrator.setParameter('stepsize','float',volumeStep);
        nativeScene.overall.append(volumeIntegrator);
             
        waterVolume = MPbrtElement('Volume','type','water');
        waterVolume.setParameter('p0','point','-5000 -5000 -1000');
        waterVolume.setParameter('p1','point',sprintf('5000 5000 %i',depth));
        waterVolume.setParameter('absorptionCurveFile','spectrum',sprintf('resources/abs_%.3f_%.3f.spd',chlConc,cdomConc));
        waterVolume.setParameter('phaseFunctionFile','string',sprintf('resources/phase_%.3f_%.3f.spd',smallPartConc,largePartConc));
        waterVolume.setParameter('scatteringCurveFile','spectrum',sprintf('resources/scat_%.3f_%.3f.spd',smallPartConc,largePartConc));
        nativeScene.world.append(waterVolume);
        
    case 'depth'      
        sampler = nativeScene.overall.find('Sampler');
        sampler.type = 'stratified';
        sampler.setParametr('xsamples','integer',1);
        sampler.setParamter('ysamples','integer',1);
        sampler.setParamter('jitter','bool','false');
            
        nativeScene.overall.find('PixelFilter');
        filter = MPbrtElement('PixelFilter','type','box');
        filter.setParameter('alpha','float',2);
        filter.setParameter('xwidth','float',0.5);
        filter.setParameter('ywidth','float',0.5);
        
    otherwise   
        filter = nativeScene.overall.find('PixelFilter');
        filter.type = 'box';
        filter.setParameter('alpha','float',2);
        filter.setParameter('xwidth','float',0.5);
        filter.setParameter('ywidth','float',0.5);       
end





end


