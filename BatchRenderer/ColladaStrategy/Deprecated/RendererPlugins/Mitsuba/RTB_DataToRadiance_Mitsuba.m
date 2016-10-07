%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert Mitsuba data to units of radiance.
%   @param multispectralImage numeric rendering data from a Render function
%   @param scene description of the scene from an ImportCollada function
%   @param hints struct of RenderToolbox4 options
%
% @details
% This the RenderToolbox4 "DataToRadiance" function for Mitsuba.
%
% @details
% For more about DataToRadiance functions see
% RTB_DataToRadiance_SampleRenderer().
%
% @details
% Usage:
%   [radianceImage, scaleFactor] = RTB_DataToRadiance_Mitsuba(multispectralImage, scene, hints)
function [radianceImage, scaleFactor] = RTB_DataToRadiance_Mitsuba(multispectralImage, scene, hints)

% get the Mitsuba radiometric scale factor
if ispref('Mitsuba', 'radiometricScaleFactor')
    scaleFactor = getpref('Mitsuba', 'radiometricScaleFactor');
else
    scaleFactor = 1;
end

% scale the rendered data to physical radiance units
radianceImage = multispectralImage .* scaleFactor;
