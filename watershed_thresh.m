function [shed1,n1,shed2,n2] = watershed_thresh(im,thresh,use26)
% ------------------------------------------------------------
% ------------------------------------------------------------

if (nargin < 3)
    use26 = 1;
else
    use26 = 0;
end

% --- Define offset index to find a voxel's neighbors ---
[nx,ny,nz] = size(im);
if (~ use26)
    %offsets = [1 -1 nx -nx nx*ny -nx*ny]; % offset to a pixel's 6 neighbors
    offsets = [1 -1 nx -nx nx*ny -nx*ny -nx-1 -nx+1 nx-1 nx+1 nx*ny-1 nx*ny+1 nx*ny-nx nx*ny+nx     -nx*ny-1 -nx*ny+1 -nx*ny-nx -nx*ny+nx  ]; 
else
    % fancy way to find the 1D offsets to all 26 neighbors of a point in the volume
    mask              = zeros(nx,ny,nz);
    mask(1:3,1:3,1:3) = 1;
    mask(2,2,2)       = 2;
    p1                = find(mask == 1);
    p2                = find(mask == 2);
    offsets           = p1 - p2(1);
end

% --- perform watershed()---
p      = find(im < thresh);
im2    = -im;
im2(p) = -Inf;
shed1  = watershed(im2);
n1     = max(shed1(:));

% --- Remove strange case where edge of volume is assigned to a watershed ---
if (shed1(1,1,1) ~= 1)
    fprintf(1,'WARNING: volume edge was assigned to a watershed. Removing it\n');
    p = find(shed1 == shed1(1,1,1));
    shed1(p) = 1;   % make it background - watershed labels background = 1
end
    
% --- Watershed makes background = 1, borders = 0. Assign borders to neighboring region ---
[shed2,count,np] = border_shed(shed1,offsets);
%fprintf(1,'Iteration 1: Assigned %1d (of %1d) border pixels to closest region.\n',count,np);
if (np > 0) && (count < np)
    [shed2,count,np] = border_shed(shed2,offsets);
    %fprintf(1,'Iteration 2: Assigned %1d (of %1d) border pixels to closest region.\n',count,np);
end

% --- Make remaining border pixels = background ---
p = find(shed2 == 0);
if (~isempty(p))
    shed2(p) = 1;
end
shed2    = shed2 - 1;     % regions go from 2...N, make them go 1...N-1
n2       = n1 - 1;
return


function [shed2,count,np] = border_shed(shed1,offsets)
% ------------------------------------------------------------
% Recover "border" pixels from watershed()
% Assign border pixels to closest watershed region
% ------------------------------------------------------------

shed2   = shed1;
p       = find(shed1 == 0);           % all border pixels
np      = size(p,1);
count   = 0;
for i=1:np                            % find 1st neighbor thats in a watershed region
    neighbors = shed1(p(i)+offsets);
    pp = find(neighbors > 1);
    if (~ isempty(pp))
        region      = neighbors(pp(1));    % arbitrarily use first neighboring region
        shed2(p(i)) = region;
        count       = count+1;
	end
end