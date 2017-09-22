function [ effFlength ] = effectiveFocalLength( lensFileName )

lens = lensC('fileName',lensFileName);
lens.bbmCreate();

wave = 400:50:700;
effFlength = lens.get('bbm','effectiveFocalLength');

effFlength = effFlength(wave==500);

end

