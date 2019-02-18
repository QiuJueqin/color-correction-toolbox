% ===================================================
% *** FUNCTION xyz2linsrgb
% ***
% *** function [linsRGB] = xyz2linsrgb(XYZ)
% *** computes linear sRGB from XYZ 
% *** XYZ is n by 3 and in the range 0-1
% *** linsRGB is n by 3 and in the range 0-1
% *** see also linsrgb2xyz
% 
% Modified based on the source version from 
% Computational Colour Science using MATLAB 2e
% https://www.mathworks.com/matlabcentral/fileexchange/
% 40640-computational-colour-science-using-matlab-2e
% ===================================================

function [RGB] = xyz2linsrgb(XYZ)
if (size(XYZ,2)~=3)
   disp('XYZ must be n by 3'); return;   
end
M = [3.2406 -1.5372 -0.4986; -0.9689 1.8758 0.0415; 0.0557 -0.2040 1.0570];
RGB = (M*XYZ')';
RGB = max(min(RGB, 1), 0);
end