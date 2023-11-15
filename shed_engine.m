function [regions] = shed_engine(actmap, params)

% --- Params ---
thresh1               = params.thresh1;
thresh2               = params.thresh2;
extent1               = params.extent1;
extent2               = params.extent2;
smooth_width          = params.smooth;                  % fwhm (in pixels)
remove_isolated_sheds = params.remove_isolated_sheds;   % removes solitary clusters w/ max < thresh2
recover_lost_clusters = params.recover_lost_clusters;   % Recovers isolated clusters removed in watershed() step
restore_cluster_edges = params.restore_cluster_edges;   % Assigns deleted cluster edges to watershed regions
                                                        % (This param also controls how many passes to do)                      
use26                 = params.use26;                   % use 26 neighbors for recovering watershed border pixels (else use 18)
         
reverse_xy            = params.reorient_images;         % reverse X,Y coordinates is print outs to match image display (crazy Matlab!)

regions = [];

fprintf(1,'\n-----------------------------------------------------------------------\n');
fprintf(1,'-----------------------------------------------------------------------\n');
fprintf(1,'Starting Watershed_actmap()\n');

im = double(actmap);
[nx,ny,nz] = size(im);

% --- smooth the map ---
if (smooth_width > 0)
    fprintf('\nSMOOTHING: Gaussian sigma = %f\n',smooth_width);
    im = smooth3(im,'gaussian',5,smooth_width);
end

% -------------------------------------------------------------------------
% --- Cluster based on threshold and extent ---
% -------------------------------------------------------------------------
fprintf(1,'\nPASS 1 - CLUSTERS: \n');
[clusters,nclust,ndiscard] = cluster_thresh(im,thresh1,extent1);
if (nclust < 1)
   fprintf(1,'ERROR: did not find any clusters with signal > %1.2f',thresh1); 
   return
end
fprintf(1,'Kept %1d clusters with extent > %1d and signal > %1.2f. Threw out %1d small clusters.\n',nclust,extent1,thresh1,ndiscard);

% --- Find centers and size of each cluster ---
[nc,csize,ccenter1d,ccenter3d,cmax,cval] = region_stats(clusters,im);
print_regions(clusters,nc,csize,ccenter3d,cmax,reverse_xy);

% --- Mask map with Clusters ---
im1 = im .* (clusters > 0);

% -------------------------------------------------------------------------
% --- Use Watershed to further separate regions ---
% -------------------------------------------------------------------------
fprintf(1,'\nPASS 2 - WATERSHEDS: \n');
[labels1,n1,labels2,nregions] = watershed_thresh(im1,thresh1,use26); % note "labels1" is never used.
if (nregions < 1)
   fprintf(1,'ERROR: Did not find any Watershed regions with signal > %6.2f\n',thresh1); 
   return
end
fprintf(1,'Found %1d watershed regions\n',nregions);

% --- Find centers and size of each region ---
[nreg,rsize,rcenter1d,rcenter3d,rmax,rval] = region_stats(labels2,im1);
rcluster = print_regions(clusters,nreg,rsize,rcenter3d,rmax,reverse_xy);

% --- Find if any clusters got removed by Watershed() ---
if (recover_lost_clusters)
  lost = 0;
  for i=1:nc
    pc = find(rcluster == i);
    if (isempty(pc))
        lost = 1;
        fprintf(1,'Original Cluster %1d was lost! Putting it back as separate watershed.\n',i);
        pr          = find(clusters == i);
        nreg        = nreg + 1;
        labels2(pr) = nreg;
    end
  end
  
  if (lost)  % report new list of watesheds
    [nreg,rsize,rcenter1d,rcenter3d,rmax,rval] = region_stats(labels2,im1);
    rcluster = print_regions(clusters,nreg,rsize,rcenter3d,rmax,reverse_xy);
  end
end

% --- Recover voxels in cluster regions deleted by watershed() ---
if (restore_cluster_edges)
    p = find((clusters > 0) & (labels2 == 0));
    [labels2,count,np] = assign_voxels(labels2,p);
%    fprintf(1,'Iteration  1: Restored %5d (of %5d) cluster edge pixels to closest region.\n',count,np);
    for i=2:restore_cluster_edges
      if (np > 0) && (count < np)
        p = find((clusters > 0) & (labels2 == 0));
        [labels2,count,np] = assign_voxels(labels2,p);
%        fprintf(1,'Iteration %2d: Restored %5d (of %5d) cluster edge pixels to closest region.\n',i,count,np);
      end
    end
end

% --- Mask map with Watershed regions ---
im2 = im1 .* (labels2 > 0);

% -------------------------------------------------------------------------
% --- Merge low-peak regions with bordering high-peak regions ---
% -------------------------------------------------------------------------
fprintf(1,'\nPASS 3 - MERGE low amplitude peaks: \n');
labels3 = labels2;
plow    = find(rmax < thresh2 & rsize ~= 0);
nlow    = size(plow,1);
fprintf(1,'Found %1d watershed regions with max < %1.2f. Merging them into neighboring regions with max > %1.2f ...\n',nlow,thresh2,thresh2); 
if (nlow > 0)
   for i=1:nlow
       r1 = rcenter3d(:,plow(i));           % R-vector loc of region to merge
       c1 = rcluster(plow(i));              % cluster that r1 is in
       l1 = rval(plow(i));                  % watershed that r1 is in
       p  = find(labels2 == l1);            % points in region

       % --- Find candidate regions to merge to (same cluster, high enough) ---
       phigh = find((rmax >= thresh2) & (rcluster == c1));  
       nhigh = size(phigh,1);

       % --- No neighboring region (i.e. not in same cluster) ---
       if (nhigh < 1)
           if (remove_isolated_sheds)
              fprintf(1,'  Removing isolated region %2d.\n',l1);
              labels3(p) = 0;
           else
              fprintf(1,'  Keeping isolated region %2d as is.\n',l1);
           end

       % --- Merge into closest neighboring region ---
       else
           rhigh      = rcenter3d(:,phigh);      % R-vector locs of candidate regions
           dist2      = sum((rhigh-r1*ones(1,nhigh)).^2,1); % dist^2 from rhigh to r1
           [tmp,imin] = min(dist2);               % find closest rhigh location
           r2         = rhigh(imin);              % r2 is closest high-peak
           l2         = rval(phigh(imin));        % watershed that r2 is in
           fprintf(1,'  Merging region %2d into region %2d.\n',l1,l2);
           labels3(p) = l2;
       end     
    end
end

% --- Squeeze down labels to remove empty ones now ---
%labels3 = region_squeeze(labels3);

% --- Recap region stats now ---
[nreg,rsize,rcenter1d,rcenter3d,rmax,rval] = region_stats(labels3,im2);
fprintf(1,'\nREGIONS now: \n');
rcluster = print_regions(clusters,nreg,rsize,rcenter3d,rmax,reverse_xy);

% --- Mask map again with Watershed regions ---
im3 = im2 .* (labels3 > 0);

% -------------------------------------------------------------------------
% --- Merge small volume peaks into larger neighbors (if any) ---
% -------------------------------------------------------------------------
fprintf(1,'\nPASS 4 - MERGE small volume peaks: \n');
labels4 = labels3;
psmall  = find(rsize < extent2 & rsize ~= 0);
nsmall  = size(psmall,1);
fprintf(1,'Found %1d watershed regions with extent < %1d. Merging them into neighboring regions with extent > %1d ...\n',nsmall,extent2,extent2); 
if (nsmall > 0)
   for i=1:nsmall
       r1 = rcenter3d(:,psmall(i));         % R-vector loc of region to merge
       c1 = rcluster(psmall(i));              % cluster that r1 is in
       l1 = rval(psmall(i));                  % watershed that r1 is in
       p  = find(labels3 == l1);            % points in region

       % --- Find candidate regions to merge to (same cluster, big enough) ---
       pbig = find((rsize >= extent2) & (rcluster == c1));  
       nbig = size(pbig,1);

       % --- No neighboring region (i.e. not in same cluster) ---
       if (nbig < 1)
           if (remove_isolated_sheds)
              fprintf(1,'  Removing isolated region %2d.\n',l1);
              labels4(p) = 0;
           else
              fprintf(1,'  Keeping isolated region %2d as is.\n',l1);
           end

       % --- Merge into closest neighboring region ---
       else
           rbig       = rcenter3d(:,pbig);      % R-vector locs of candidate regions
           dist2      = sum((rbig-r1*ones(1,nbig)).^2,1); % dist^2 from rbig to r1
           [tmp,imin] = min(dist2);               % find closest rbig location
           r2         = rbig(imin);              % r2 is closest big-peak
           l2         = rval(pbig(imin));        % watershed that r2 is in
           fprintf(1,'  Merging region %2d into region %2d.\n',l1,l2);
           labels4(p) = l2;
       end     
    end
end

% --- Squeeze down labels to remove empty ones now ---
%labels4 = region_squeeze(labels4);

% --- Recap region stats now ---
[nreg,rsize,rcenter1d,rcenter3d,rmax,rval] = region_stats(labels4,im3);
fprintf(1,'\nREGIONS now: \n');
rcluster = print_regions(clusters,nreg,rsize,rcenter3d,rmax,reverse_xy);

% --- Mask map again with Watershed regions ---
im4 = im3 .* (labels4 > 0);

% --- Split up any watershed regions that are not a single contiguous blob ---
fprintf(1,'\nPASS 5 - SPLIT regions that are not a single contiguous group (rare): \n');
labels5 = zeros(nx,ny,nz);
[clust2,nclust2,ndiscard] = cluster_thresh(im4,thresh1,extent1);
split_count = 0;
for i=1:nreg
    if (rsize(i) ~= 0)
        lab1 = (labels4 == i);
        lab2 = clust2 .* lab1;
        [lab3,n3] = region_squeeze(lab2);   
        labels5 = labels5 + (lab3 == 1) * i;
        if (n3 > 1)
            fprintf(1,'  Region %2d needs to be split into %1d sub-regions.\n',i,n3);
            split_count = split_count+1;
            for j=2:n3
                new_region = (i + (j-1)*nreg);
                fprintf(1,'    Creating new region %2d.\n',new_region);
                labels5 = labels5 + (lab3 == j) * new_region;
            end
        else
        end
    end
end
if (split_count == 0), fprintf(1,'  Found no non-contiguous regions.\n'); end
%labels5 = clust2 * (nreg+1) + labels4;
%labels5 = region_squeeze(labels5);
[nreg,rsize,rcenter1d,rcenter3d,rmax,rval] = region_stats(labels5,im4);
rcluster = print_regions(clusters,nreg,rsize,rcenter3d,rmax,reverse_xy);

% --- Mask map again with Watershed regions ---
im5 = im4 .* (labels5 > 0);

% --- Calculate voxel distanc-from-region-peak map ---
fprintf(1,'\nPASS 6 - calculate voxel distances from label peak\n');
distmap = zeros(nx,ny,nz) - 1;  % label unassigned voxels with -1
%%[x,y,z] = meshgrid(1:nx,1:ny,1:nz);
[y,x,z] = meshgrid(1:ny,1:nx,1:nz); % note nx and ny are swapped!
for i=1:nreg
    if (rsize(i) ~= 0)
        plab = find(labels5 == i); % this is the 1d index of labeled voxels
        xlab = x(plab);
        ylab = y(plab);
        zlab = z(plab);
        rlab = sqrt( (xlab-rcenter3d(1,i)).^2 + (ylab-rcenter3d(2,i)).^2 + (zlab-rcenter3d(3,i)).^2 );
        distmap(plab) = rlab;
    end
end

% --- make returned maps in a 4D array ---
regions = zeros(nx,ny,nz,6);
regions(:,:,:,6) = distmap;
regions(:,:,:,5) = labels5;
regions(:,:,:,4) = labels4;
regions(:,:,:,3) = labels3;
regions(:,:,:,2) = labels2;
regions(:,:,:,1) = clusters;

disp('Done.');
return


% ----------------------------------------------------------------------------------
function rcluster = print_regions(clusters,nreg,rsize,rcenter3d,rmax,reverse_xy)

if (nargin < 6), reverse_xy = 0; end    % reverse X&Y to match image display?

rcluster = zeros(nreg,1);
for i=1:nreg
    if (rsize(i) > 0 )
        rcluster(i,1) = clusters(rcenter3d(1,i),rcenter3d(2,i),rcenter3d(3,i));
        if (reverse_xy)
            fprintf(1,'Region: %2d  Cluster: %2d  Max: %6.2f  Size: %4d Center: (%2d %2d %2d)\n',i,rcluster(i),rmax(i),rsize(i),rcenter3d(2,i),rcenter3d(1,i),rcenter3d(3,i));
        else
            fprintf(1,'Region: %2d  Cluster: %2d  Max: %6.2f  Size: %4d Center: (%2d %2d %2d)\n',i,rcluster(i),rmax(i),rsize(i),rcenter3d(1,i),rcenter3d(2,i),rcenter3d(3,i));
        end
    end
end
return
