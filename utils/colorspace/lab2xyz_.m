% ===================================================
% *** FUNCTION lab2xyz
% ***
% *** function [xyz] = lab2xyz(lab, obs, xyzw)
% *** computes XYZ from LAB 
% *** lab is an n by 3 matrix 
% *** e.g. set obs to 'd65_64 for D65 and 1964
% *** set obs to 'user' to use optional argument   
% *** xyzw as the white point
% 
% IMPORTANT NOTE:
% Output xyz will be within range [0, 100] instead of [0, 1] !!!
% Remember to use 'xyz = xyz/100;' if you were about to call xyz2linsrgb()
% straight after lab2xyz().
%
% Modified based on the source version from 
% Computational Colour Science using MATLAB 2e
% https://www.mathworks.com/matlabcentral/fileexchange/
% 40640-computational-colour-science-using-matlab-2e
% ===================================================

function [xyz] = lab2xyz_(lab,obs,xyzw)

if nargin < 2
    obs = 'd65_31'; % default obs
end

if strcmp('a_64',obs)
    white=[111.144 100.00 35.200];
elseif strcmp('a_31', obs)
    white=[109.850 100.00 35.585];
elseif strcmp('c_64', obs)
    white=[97.285 100.00 116.145];
elseif strcmp('c_31', obs)
    white=[98.074 100.00 118.232];
elseif strcmp('d50_64', obs)
    white=[96.720 100.00 81.427];
elseif strcmp('d50_31', obs)
    white=[96.422 100.00 82.521];
elseif strcmp('d55_64', obs)
    white=[95.799 100.00 90.926];
elseif strcmp('d55_31', obs)
    white=[95.682 100.00 92.149];
elseif strcmp('d65_64', obs)
    white=[94.811 100.00 107.304];
elseif strcmp('d65_31', obs)
    white=[95.047 100.00 108.883];
elseif strcmp('d75_64', obs)
    white=[94.416 100.00 120.641];
elseif strcmp('d75_31', obs)
    white=[94.072 100.00 122.638];
elseif strcmp('f2_64', obs)
    white=[103.279 100.00 69.027];
elseif strcmp('f2_31', obs)
    white=[99.186 100.00 67.393];
elseif strcmp('f7_64', obs)
    white=[95.792 100.00 107.686];
elseif strcmp('f7_31', obs)
    white=[95.041 100.00 108.747];
elseif strcmp('f11_64', obs)
    white=[103.863 100.00 65.607]; 
elseif strcmp('f11_31', obs)
    white=[100.962 100.00 64.350];
elseif strcmp('user', obs)
    white=xyzw;
else
   disp('unknown option obs'); 
   disp('use d65_64 for D65 and 1964 observer'); return;
end

if (size(lab,2)~=3)
   disp('lab must be n by 3'); return;   
end

xyz = zeros(size(lab,1),size(lab,2));

% compute Y
index = (lab(:,1) > 7.9996);
xyz(:,2) = xyz(:,2) + index.*(white(2)*((lab(:,1)+16)/116).^3);
xyz(:,2) = xyz(:,2) + (1-index).*(white(2)*lab(:,1)/903.3);

% compute fy for use later
fy = xyz(:,2)/white(2);
index = (fy > 0.008856);
fy = zeros(size(lab,1),1);
fy = fy + (index).*(xyz(:,2)/white(2)).^(1/3);
fy = fy + (1-index).*(7.787*xyz(:,2)/white(2) + 16/116);

% compute X
index = ((lab(:,2)/500 + fy).^3 > 0.008856);
xyz(:,1) = xyz(:,1) + (index).*(white(1)*(lab(:,2)/500 + fy).^3);
xyz(:,1) = xyz(:,1) + (1-index).*(white(1)*((lab(:,2)/500 + fy) - 16/116)/7.787);

% compute Z
index = ((fy - lab(:,3)/200).^3 > 0.008856);
xyz(:,3) = xyz(:,3) + (index).*(white(3)*(fy - lab(:,3)/200).^3);
xyz(:,3) = xyz(:,3) + (1-index).*(white(3)*((fy - lab(:,3)/200) - 16/116)/7.787);

if lab(1)>7.9996
    t(1) = white(1)*(lab(2)/500 +(lab(1)+16)/116)^3;
    t(2) = white(2)*((lab(1)+16)/116)^3;
    t(3) = white(3)*(-lab(3)/200+(lab(1)+16)/116)^3;
else
    t(1) = white(1)*(lab(2)/500 +lab(1)/116)/7.787;
    t(2) = white(2)*lab(1)/(116*7.787);
    t(3) = white(3)*(-lab(3)/200+lab(1)/116)/7.787;
end
disp([xyz; t])





end







