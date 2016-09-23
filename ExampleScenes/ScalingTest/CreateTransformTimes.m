function nativeScene = CreateTransformTimes(parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
% Add TransformTimes element with conditions file shutterOpen and shutterClose

shutterOpen = rtbGetNamedValue(names, conditionValues, 'shutterOpen', 0);
shutterClose = rtbGetNamedValue(names, conditionValues, 'shutterClose', 1);
shutterWindow = [sscanf(shutterOpen, '%f') sscanf(shutterClose, '%f')];
transformTimes = MPbrtElement.transformation('TransformTimes', shutterWindow);
nativeScene.append(transformTimes);
