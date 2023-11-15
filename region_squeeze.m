function [newim,nreg] = region_squeeze(im)
% ------------------------------------------------------------
% Remove empty labeled regions from a label image
% ------------------------------------------------------------

nreg        = max(im(:));
newim       = im;
label_count = 0;
for i=1:nreg
   p  = find(im == i);
   np = size(p,1);
   if (np > 0)
       label_count = label_count + 1;
       newim(p)    = label_count;
   end
end

nreg = label_count;
return
