%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get version information about the Sample Renderer.
%
% @details
% This function is a template for a RenderToolbox4 "VersionInfo" function.
%
% @details
% The name of a VersionInfo function must match a specific pattern: it must
% begin with "RTB_VersionInfo_", and it must end with the name of the
% renderer, for example, "SampleRenderer".  This pattern allows
% RenderToolbox4 to automatically locate the VersionInfo function for each
% renderer.  VersionInfo functions should be included in the Matlab path.
%
% @details
% A VersionInfo function must return information about a renderer's
% version.  This may have any form, including string or struct.  The may
% have any content, including a software revision or version name or
% number, a renderer executable file creation date, etc.  RenderToolbox4
% uses VersionInfo functions to save renderer version information along
% with rendering data.
%
% Usage:
%   versionInfo = RTB_VersionInfo_SampleRenderer()
%
% @ingroup RendererPlugins
function versionInfo = RTB_VersionInfo_SampleRenderer()

disp('SampleRenderer VersionInfo function.')

versionInfo = 'SampleRenderer version information';
