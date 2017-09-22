function [ cameras ] = rtbCamerasPlace( cameras, objects )
% Assign camera values to look at the object position
%
%
% HB SCIEN Stanford, 2017

%%
nArrangements = length(objects);
cameras = repmat({cameras},[1, nArrangements]);

for a=1:nArrangements
    for i=1:length(cameras{a})
        
        % Which object - this is an index
        lookAtObject = cameras{a}(i).lookAtObject;
        
        % Find the object position
        objPosition = objects{a}(lookAtObject).position;
        
        % Set the camera position and lookat direction towards that object
        cx = cameras{a}(i).distance*sind(cameras{a}(i).orientation) + objPosition(1);
        cy = cameras{a}(i).distance*cosd(cameras{a}(i).orientation) + objPosition(2);
        cameras{a}(i).position = [cx, cy, cameras{a}(i).height];
        cameras{a}(i).lookAt = objPosition;
        cameras{a}(i).lookAt(3) = cameras{a}(i).height;
        
        % Set the camera film distance to be in focus for the object?
        lensFile = fullfile(rtbRoot,'RenderData','Lenses',sprintf('%s.dat',cameras{a}(i).lens));
        if strcmp(cameras{a}(i).type,'pinhole')
            cameras{a}(i).filmDistance = effectiveFocalLength(lensFile);
        else
            % Uses CISET to find the sensor distance
            % Why is the object distance stored in cameras?
            cameras{a}(i).filmDistance = focusLens(lensFile,cameras{a}(i).distance);
            if cameras{a}(i).defocus ~= 0
                lens = lensC('fileName',lensFile);
                focalLength = lens.focalLength;
                
                % Units are unspecified, and scaling by 1000 is a problem
                % throughout. (BW).
                
                % Equivalent to focusLens in previous if/else block
                sensorInFocus = 1/(1/(focalLength/1000) - 1/cameras{a}(i).distance);
                sensorOutOfFocus = 1/(1/(focalLength/1000) + cameras{a}(i).defocus - 1/cameras{a}(i).distance);
                
                delta = (sensorOutOfFocus - sensorInFocus)*1000;
                
                cameras{a}(i).filmDistance = cameras{a}(i).filmDistance + delta;
            end
        end
        
    end
end


end

