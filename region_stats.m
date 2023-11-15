function [nreg,rsize,rcenter1d,rcenter3d,rmax,rval,nreg_nonempty] = region_stats(regions,im)
% ------------------------------------------------------------
% ------------------------------------------------------------

[nx,ny,nz] = size(regions);

nreg          = double(max(regions(:)));
nreg_nonempty = 0;                  % number of non-empty regions found
rsize         = zeros(nreg,1);
rmax          = zeros(nreg,1);
rval          = zeros(nreg,1);
rcenter1d     = zeros(nreg,1);
rcenter3d     = zeros(3,nreg);

for i=1:nreg
    p = find(regions == i);
    rsize(i) = size(p,1);
    if (rsize(i) > 0)
        nreg_nonempty = nreg_nonempty + 1;
        rval(i) = i;
        [rmax(i),index] = max(im(p));
    	rcenter1d(i) = p(index);            % 1D subscript for max voxel location
        point = rcenter1d(i)-1;             % convert to 3D subscripts
        x0 = mod(point,nx) + 1;             
        y0 = mod( fix(point/nx), ny) + 1;
        z0 = fix(point/(nx*ny)) + 1;
        rcenter3d(:,i) = [x0,y0,z0];
    else
        rval(i) = -1;
    end
end

return

