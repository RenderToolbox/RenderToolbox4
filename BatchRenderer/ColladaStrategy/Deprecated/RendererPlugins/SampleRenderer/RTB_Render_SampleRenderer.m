%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Invoke the Sample Renderer.
%   @param scene struct description of the scene to be rendererd
%   @param hints struct of RenderToolbox4 options
%
% @details
% This function is a template for a RenderToolbox4 "Render" function.
%
% @details
% The name of a Render function must match a specific pattern: it must
% begin with "RTB_Render_", and it must end with the name of the renderer,
% for example, "SampleRenderer".  This pattern allows RenderToolbox4 to
% automatically locate the Render function for each renderer.  Render
% functions should be included in the Matlab path.
%
% @details
% A Render function must invoke a renderer using the given @a scene.  @a
% scene will be a struct scene description returned from the ImportCollada
% function for the same renderer.
%
% @details
% RenderToolbox4 does not care how the renderer is invoked.  Some
% possibilities are:
%	- use Matlab's system() command to invoke an external application
%   - call another m-function
%   - call a Java method directly from Matlab
%   - call a mex function directly from Matlab
%   .
%
% @details
% A Render function must return three outputs:
%   - @b status: numeric status code that is 0 when rendering succeeds,
%   non-zero otherwise
%   - @b result: any text output from the renderer, or empty ''
%   - @b multispectralImage: double matrix with rendererd multispectral
%   image, of size [height width nSpectralPlanes]
%   - @b S: description of wavelengths for multispectralImage spectral
%   planes, of the form [start, delta, nSpectralPlanes].  See Psychtoolbox
%   WlsToS().
%
% @details
% This template function returns sample values but does not render anyting.
%
% Usage:
%   [status, result, multispectralImage, S] = RTB_Render_SampleRenderer(scene, hints)
%
% @ingroup RendererPlugins
function [status, result, multispectralImage, S] = RTB_Render_SampleRenderer(scene, hints)

disp('SampleRenderer Render function.')
disp('scene is:')
disp(scene)
disp('hints is:')
disp(hints)

status = 0;
result = 'SampleRenderer Render result';
S = WlsToS((400:10:700)');
multispectralImage = scene.value * ones(scene.height, scene.width, S(3));
