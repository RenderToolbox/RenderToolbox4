%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Invoke Mitsuba.
%   @param scene struct description of the scene to be rendererd
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% This function is the RenderToolbox4 "Render" function for Mitsuba.
%
% @details
% See RTB_Render_SampleRenderer() for more about Render functions.
%
% Usage:
%   [status, result, multispectralImage, S] = RTB_Render_Mitsuba(scene, hints)
function [status, result, multispectralImage, S] = RTB_Render_Mitsuba(scene, hints)

renderer = RtbMitsubaRenderer(hints);
[status, result, multispectralImage, S] = renderer.render(scene.mitsubaFile);
