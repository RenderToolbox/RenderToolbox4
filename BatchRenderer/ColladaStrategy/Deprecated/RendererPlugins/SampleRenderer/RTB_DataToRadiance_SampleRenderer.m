%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert Sample Renderer data to units of radiance.
%   @param multispectralImage numeric rendering data from a Render function
%   @param scene description of the scene from an ImportCollada function
%   @param hints struct of RenderToolbox4 options
%
% @details
% This function is a template for a RenderToolbox4 "DataToRadiance"
% function.
%
% @details
% The name of a DataToRadiance function must match a specific pattern: it
% must begin with "RTB_DataToRadiance_", and it must end with the name of
% the renderer, for example, "SampleRenderer".  This pattern allows
% RenderToolbox4 to automatically locate the DataToRadiance function for
% each renderer.  DataToRadiance functions should be included in the Matlab
% path.
%
% @details
% A DataToRadiance function must convert the @a multispectralImage data
% that was returned from a RenderToolbox4 Render function into inits of
% physical radiance.  It must also accept a @a scne parameter, as
% returned from a RenderToolbox4 ImportCollada function, which describes
% the rendered scene and may provide scene-specific and renderer-specific
% data to informs the conversion to radiance units.  It must also accept a
% @a hints parameter of RenderTooblox3 options, which also may inform the
% conversion.
%
% @details
% Converting a multispectralImage to units of physical radiance units is a
% highly-renderer specific proicess.  Some renderers may be able to return
% images in radiance units natively, in which case the DataToRadiance
% function simply return the @a multispectralImage.  Other renderers might
% return data that is a scaled version of radiance, in which case the
% DataToRadiance should apply the proper scale factor to the @a
% multispectralImage.  Determining the proper scale factor probably
% requires prior investigation.
%
% @details
% For some renderers, the proper scale factor may depend on partcular scene
% parameters, like the nubmer of ray samples used or the type of sample
% integrator.  In this case, @a scene and @a hints should be used to choose
% or calculate a proper scale factor.  Getting this right may require a lot
% of prior investigation, which may not be feasible in all cases.  A
% DataToRadiance should make a best effort to return accurate radiance
% units, and raise a warning when it is unable to do so.
%
% @details
% A DataToRadiance function must return the given @a multispectralImage,
% scaled into units of physical radiance.  It must also return the scale
% factor that was applied to the original @a multispectralImage.
%
% @details
% Usage:
%   [radianceImage, scaleFactor] = RTB_DataToRadiance_SampleRenderer(multispectralImage, scene, hints)
%
% @ingroup RendererPlugins
function [radianceImage, scaleFactor] = RTB_DataToRadiance_SampleRenderer(multispectralImage, scene, hints)

disp('SampleRenderer DataToRadiance function')
disp('multispectralImage is:')
disp(multispectralImage);
disp('scene is:')
disp(scene);
disp('hints is:')
disp(hints);

scaleFactor = 2;
radianceImage = scaleFactor .* multispectralImage;