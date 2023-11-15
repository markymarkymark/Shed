function [im2,count,np] = assign_voxels(im1,p)
% ------------------------------------------------------------
% Assign pixels to closest non-zero region
% ------------------------------------------------------------

% fancy way to find the 1D offsets to all 26 neighbors of a point in the volume
[nx,ny,nz]        = size(im1);
mask              = zeros(nx,ny,nz);
mask(1:3,1:3,1:3) = 1;
mask(2,2,2)       = 2;
p1                = find(mask == 1);
p2                = find(mask == 2);
offsets           = p1 - p2(1);

im2     = im1;
np      = size(p,1);
count   = 0;
for i=1:np                            % find 1st neighbor that is non-zero
    neighbors = im1(p(i)+offsets);
    pp = find(neighbors > 0);
    if (~ isempty(pp))
        region    = neighbors(pp(1));    % arbitrarily use first neighboring region
        im2(p(i)) = region;
        count     = count+1;
	end
end