function oi = rtbOICreate(photons,varargin)
% Create an oi from radiance data
%
%     oi = rtbOICreate(photons,varargin)
%
% Required
%    photons - row x col x nwave data, computed by PBRT usually
%
% Key/values
%    focalLength - meters
%    fNumber     - dimensionless
%    filmDiag    - meters
%    fov         - horizontal field of view (deg)
%
% Return
%  An ISET oi structure
%
% Note:  If fov and filmdiag are not set, we use fov = 40;
%        If fov is set, we use it
%        If fov is not set, we use filmdiag.
%  
% BW, SCIENTSTANFORD, 2017

%%
p = inputParser;
p.addRequired('photons',@isnumeric);
p.addParameter('focalLength',0.004,@isscalar);   % Meters
p.addParameter('fNumber',4,@isscalar);           % Dimensionless
p.addParameter('filmDiag',[],@isscalar);         % Meters
p.addParameter('fov',[],@isscalar)               % Horizontal fov, degrees

p.parse(photons,varargin{:});

%%  In this case, we don't always have ISET properly initialized.  
%
% So we handle the main issue here
global vcSESSION
if ~isfield(vcSESSION,'SCENE')
    vcSESSION.SCENE = {};
end

%%
oi = oiCreate;
oi = initDefaultSpectrum(oi);
oi = oiSet(oi,'photons',photons);
oi = oiSet(oi, 'optics focal length', p.Results.focalLength);
oi = oiSet(oi,'optics fnumber',p.Results.fNumber);

[r,c] = size(photons(:,:,1)); depthMap = ones(r,c);
oi = oiSet(oi,'depth map',depthMap);

% Deal with the field of view, which apparently needs to be set for oi to work
% correctly.  The logic is set to 40 if the person tells you nothing.  If they
% tell you the fov, use it.  If they don't tell you the fov but they do tell you
% the filmdiag, compute the fov.
if isempty(p.Results.fov) && isempty(p.Results.filmDiag)
    fov = 40;
elseif isempty(p.Results.fov)
    % We must the filmdiag
    photons = oiGet(oi, 'photons');
    x = size(photons, 1);
    y = size(photons, 2);
    d = sqrt(x^2 + y^2);  % Number of samples along the diagonal
    fwidth= (p.Results.filmDiag / d) * x;    % Diagonal size by d gives us mm per step
    
    % multiplying by x gives us the horizontal mm
    % Calculate angle in degrees
    fov = 2 * atan2d(fwidth / 2, p.Results.focalLength);
else
    % We have the fov
    fov = p.Results.fov;
end
oi = oiSet(oi,'fov',fov);

%ieAddObject(oi); oiWindow;

end