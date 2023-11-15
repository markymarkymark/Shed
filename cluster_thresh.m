function [labels,nkept,nlost] = cluster_thresh(im,thresh,extent)
% Weed image for cluster extent
% M.Elliott 
%------------------------------------------------------------------------

nkept  = 0;
nlost  = 0;
tim    = im > thresh;
labels = im*0;
[clusts,nclust] = bwlabeln(tim);
for i=1:nclust
    p = find(clusts == i);
    np = size(p,1);
    if (np < extent)
        nlost = nlost + 1;
    else
        nkept = nkept + 1;
        labels(p) = nkept;
    end
end
%{
for i=1:nkept
   fprintf(1,'cluster %2d: size = %5d\n',i,sum(labels(:) == i));
end
fprintf(1,'Kept %1d clusters with extent > %1d. Threw out %1d small clusters.\n',nkept,extent,nlost);
%}
return