% This demo shows the color correction pipeline with white point preserved.
% 
% Copyright
% Qiu Jueqin - Feb, 2019

clear; close all; clc;

%% data preparation

% load DSG color checker's spectral reflectance data
load('spectral_reflectance_data.mat');
spectra = spectral_reflectance_data.XRite_DSG;

% calculate the XYZ values for the color checker under D65
XYZ = spectra2colors(spectra, 400:5:700,...
                     'spd', 'D65');

% read color checker image and extract color responses
% the darkness level and the spatial non-uniformity has been corrected for
% this image
dsg_img = imread('dsg_Nikon_D3x.tiff');

% you can also manually select roi for the color checker
roi = [519,310,65,65;669,309,65,65;819,308,65,65;969,307,65,65;1120,306,65,65;1270,306,65,65;1421,305,65,65;1572,304,65,65;1722,303,65,65;1873,302,65,65;2025,301,65,65;2176,300,65,65;2327,299,65,65;2479,299,65,65;519,460,65,65;669,459,65,65;819,458,65,65;970,457,65,65;1120,456,65,65;1271,456,65,65;1421,455,65,65;1572,454,65,65;1723,453,65,65;1874,452,65,65;2025,452,65,65;2176,451,65,65;2328,450,65,65;2479,449,65,65;519,650,65,65;669,609,65,65;820,608,65,65;970,607,65,65;1120,607,65,65;1271,606,65,65;1422,605,65,65;1572,604,65,65;1723,604,65,65;1874,603,65,65;2026,602,65,65;2177,601,65,65;2328,601,65,65;2480,600,65,65;520,760,65,65;670,759,65,65;820,758,65,65;970,758,65,65;1121,757,65,65;1271,756,65,65;1422,755,65,65;1573,755,65,65;1724,754,65,65;1875,753,65,65;2026,753,65,65;2177,752,65,65;2329,751,65,65;2480,751,65,65;520,910,65,65;670,909,65,65;820,908,65,65;971,908,65,65;1121,907,65,65;1272,907,65,65;1422,906,65,65;1573,905,65,65;1724,905,65,65;1875,904,65,65;2027,903,65,65;2178,903,65,65;2329,902,65,65;2481,901,65,65;520,1060,65,65;670,1059,65,65;820,1059,65,65;971,1058,65,65;1121,1057,65,65;1272,1057,65,65;1423,1056,65,65;1574,1056,65,65;1725,1055,65,65;1876,1055,65,65;2027,1054,65,65;2179,1053,65,65;2330,1053,65,65;2482,1052,65,65;520,1210,65,65;670,1209,65,65;821,1209,65,65;971,1208,65,65;1122,1208,65,65;1272,1207,65,65;1423,1207,65,65;1574,1206,65,65;1725,1206,65,65;1876,1205,65,65;2028,1205,65,65;2179,1204,65,65;2331,1204,65,65;2482,1203,65,65;520,1360,65,65;671,1360,65,65;821,1359,65,65;972,1359,65,65;1122,1358,65,65;1273,1358,65,65;1424,1357,65,65;1575,1357,65,65;1726,1357,65,65;1877,1356,65,65;2028,1356,65,65;2180,1355,65,65;2331,1355,65,65;2483,1354,65,65;521,1510,65,65;671,1510,65,65;821,1510,65,65;972,1509,65,65;1122,1509,65,65;1273,1508,65,65;1424,1508,65,65;1575,1508,65,65;1726,1507,65,65;1877,1507,65,65;2029,1507,65,65;2180,1506,65,65;2332,1506,65,65;2484,1505,65,65;521,1661,65,65;671,1660,65,65;822,1660,65,65;972,1660,65,65;1123,1659,65,65;1274,1659,65,65;1424,1659,65,65;1576,1658,65,65;1727,1658,65,65;1878,1658,65,65;2029,1657,65,65;2181,1657,65,65;2332,1657,65,65;2484,1656,65,65];
RGB = checker2colors(dsg_img, [10, 14],...
                     'roi', roi,...
                     'show', false,...
                     'scale', 4); % scaling only for better visualization

clearvars -except XYZ RGB


%% color correction with white point preserved

% white balancing RGB values
neutral_patches_idx = [61, 62, 63, 64, 65];
gains = [RGB(neutral_patches_idx, 1) \ RGB(neutral_patches_idx, 2),...
         1,...
         RGB(neutral_patches_idx, 3) \ RGB(neutral_patches_idx, 2)];
     
RGB_wb = RGB .* gains;

% use D65's XYZ value as white point to be preserved after color correction
white_point = whitepoint('d65');

% training
model = 'root6x3';
[matrix, scale, XYZ_pred, errs_train] = ccmtrain(RGB_wb,...
                                                 XYZ,...
                                                 'model', model,...
                                                 'targetcolorspace', 'xyz',...
                                                 'whitepoint', white_point);

% check if [1, 1, 1] has been preserved as [0.9505, 1.0000, 1.0888]
predicted_white_point = ccmapply([1, 1, 1],...
                                 model,...
                                 matrix);
                        
white_point_err = sqrt(sum((predicted_white_point - white_point).^2));
fprintf('residual error between user-specified and predicted white points: %.3e\n', white_point_err);

% visualization
figureFullScreen('color', 'w');
ax1 = subplot(1,2,1);
colors2checker(RGB_wb .^ (1/2.2),...
               'layout', [10, 14],...
               'squaresize', 100,...
               'parent', ax1);
title('White balaned camera responses before color correction (gamma = 1/2.2)');

ax2 = subplot(1,2,2);
colors2checker(xyz2rgb(XYZ_pred),...
               'layout', [10, 14],...
               'squaresize', 100,...
               'parent', ax2);
title('Camera responses (sRGB) after color correction');
                        