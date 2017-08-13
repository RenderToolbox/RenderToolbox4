function [ cameras ] = nnPlaceCameras( cameras, objects )

global lensDir

nArrangements = length(objects);
cameras = repmat({cameras},[1, nArrangements]);

for a=1:nArrangements
    for i=1:length(cameras{a})
        lookAtObject = cameras{a}(i).lookAtObject;
        objPosition = objects{a}(lookAtObject).position;
        
        cx = cameras{a}(i).distance*sind(cameras{a}(i).orientation) + objPosition(1);
        cy = cameras{a}(i).distance*cosd(cameras{a}(i).orientation) + objPosition(2);
        
        cameras{a}(i).position = [cx, cy, cameras{a}(i).height];
        cameras{a}(i).lookAt = objPosition;
        cameras{a}(i).lookAt(3) = cameras{a}(i).height;
        
        lensFile = fullfile(lensDir,sprintf('%s.dat',cameras{a}(i).lens));
        if strcmp(cameras{a}(i).type,'pinhole')
            cameras{a}(i).filmDistance = effectiveFocalLength(lensFile);
        else
            cameras{a}(i).filmDistance = focusLens(lensFile,cameras{a}(i).distance);
            if cameras{a}(i).defocus ~= 0
                lens = lensC('fileName',lensFile);
                focalLength = lens.focalLength;
                
                sensorInFocus = 1/(1/(focalLength/1000) - 1/cameras{a}(i).distance);
                sensorOutOfFocus = 1/(1/(focalLength/1000) + cameras{a}(i).defocus - 1/cameras{a}(i).distance);
                
                delta = (sensorOutOfFocus - sensorInFocus)*1000;
                
                cameras{a}(i).filmDistance = cameras{a}(i).filmDistance + delta;
            end
        end
        
    end
end


end

