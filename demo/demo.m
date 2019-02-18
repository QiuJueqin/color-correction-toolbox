% This demo shows the complete color correction pipeline for digital
% cameras and will help you understand the uses of core functions in Color
% Correction Toolbox.
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

% split the left half as training samples and the right half as validation
XYZ = reshape(XYZ, 14, 10, 3);
XYZ_train = reshape(XYZ(1:7, :, :), [], 3);
XYZ_val = reshape(XYZ(8:14, :, :), [], 3);

% visualize the target colors
figureFullScreen('color', 'w');
ax1 = subplot(1,2,1);
colors2checker(xyz2rgb(XYZ_train),...
               'layout', [10, 7],...
               'squaresize', 100,...
               'parent', ax1);
title('Training samples (target sRGB)');
           
ax2 = subplot(1,2,2);
colors2checker(xyz2rgb(XYZ_val),...
               'layout', [10, 7],...
               'squaresize', 100,...
               'parent', ax2);
title('Validation samples (target sRGB)');

% read color checker image and extract color responses
% the darkness level and the spatial non-uniformity has been corrected for
% this image
dsg_img = imread('dsg_Nikon_D3x.tiff');

% you can also manually select roi for the color checker
roi = [519,310,65,65;669,309,65,65;819,308,65,65;969,307,65,65;1120,306,65,65;1270,306,65,65;1421,305,65,65;1572,304,65,65;1722,303,65,65;1873,302,65,65;2025,301,65,65;2176,300,65,65;2327,299,65,65;2479,299,65,65;519,460,65,65;669,459,65,65;819,458,65,65;970,457,65,65;1120,456,65,65;1271,456,65,65;1421,455,65,65;1572,454,65,65;1723,453,65,65;1874,452,65,65;2025,452,65,65;2176,451,65,65;2328,450,65,65;2479,449,65,65;519,650,65,65;669,609,65,65;820,608,65,65;970,607,65,65;1120,607,65,65;1271,606,65,65;1422,605,65,65;1572,604,65,65;1723,604,65,65;1874,603,65,65;2026,602,65,65;2177,601,65,65;2328,601,65,65;2480,600,65,65;520,760,65,65;670,759,65,65;820,758,65,65;970,758,65,65;1121,757,65,65;1271,756,65,65;1422,755,65,65;1573,755,65,65;1724,754,65,65;1875,753,65,65;2026,753,65,65;2177,752,65,65;2329,751,65,65;2480,751,65,65;520,910,65,65;670,909,65,65;820,908,65,65;971,908,65,65;1121,907,65,65;1272,907,65,65;1422,906,65,65;1573,905,65,65;1724,905,65,65;1875,904,65,65;2027,903,65,65;2178,903,65,65;2329,902,65,65;2481,901,65,65;520,1060,65,65;670,1059,65,65;820,1059,65,65;971,1058,65,65;1121,1057,65,65;1272,1057,65,65;1423,1056,65,65;1574,1056,65,65;1725,1055,65,65;1876,1055,65,65;2027,1054,65,65;2179,1053,65,65;2330,1053,65,65;2482,1052,65,65;520,1210,65,65;670,1209,65,65;821,1209,65,65;971,1208,65,65;1122,1208,65,65;1272,1207,65,65;1423,1207,65,65;1574,1206,65,65;1725,1206,65,65;1876,1205,65,65;2028,1205,65,65;2179,1204,65,65;2331,1204,65,65;2482,1203,65,65;520,1360,65,65;671,1360,65,65;821,1359,65,65;972,1359,65,65;1122,1358,65,65;1273,1358,65,65;1424,1357,65,65;1575,1357,65,65;1726,1357,65,65;1877,1356,65,65;2028,1356,65,65;2180,1355,65,65;2331,1355,65,65;2483,1354,65,65;521,1510,65,65;671,1510,65,65;821,1510,65,65;972,1509,65,65;1122,1509,65,65;1273,1508,65,65;1424,1508,65,65;1575,1508,65,65;1726,1507,65,65;1877,1507,65,65;2029,1507,65,65;2180,1506,65,65;2332,1506,65,65;2484,1505,65,65;521,1661,65,65;671,1660,65,65;822,1660,65,65;972,1660,65,65;1123,1659,65,65;1274,1659,65,65;1424,1659,65,65;1576,1658,65,65;1727,1658,65,65;1878,1658,65,65;2029,1657,65,65;2181,1657,65,65;2332,1657,65,65;2484,1656,65,65];
RGB = checker2colors(dsg_img, [10, 14],...
                     'roi', roi,...
                     'scale', 4); % scaling only for better visualization

% split the left half as training samples and the right half as validation
RGB = reshape(RGB, 14, 10, 3);
RGB_train = reshape(RGB(1:7, :, :), [], 3);
RGB_val = reshape(RGB(8:14, :, :), [], 3);

% visualize the camera colors
figureFullScreen('color', 'w');
ax1 = subplot(1,2,1);
colors2checker(RGB_train,...
               'layout', [10, 7],...
               'squaresize', 100,...
               'parent', ax1);
title('Training samples (camera RGB, w/o gamma)');

ax2 = subplot(1,2,2);
colors2checker(RGB_val,...
               'layout', [10, 7],...
               'squaresize', 100,...
               'parent', ax2);
title('Validation samples (camera RGB, w/o gamma)');

clearvars -except XYZ_train XYZ_val RGB_train RGB_val

%% color correction

% training
model = 'root6x3'; % color correction model
targetcolorspace = 'XYZ';
metrics = {'mse', 'ciede00', 'ciedelab'}; % only for evaluation

% default loss function: ciede00
% if RGB_train has been white-balanced, consider using 'preservewhite' and
% 'whitepoint' parameters.
[matrix, scale, XYZ_train_pred, errs_train] = ccmtrain(RGB_train,...
                                                       XYZ_train,...
                                                       'model', model,...
                                                       'bias', true,...
                                                       'targetcolorspace', targetcolorspace,...
                                                       'metric', metrics);
% validation
[XYZ_val_pred, errs_val] = ccmvalidate(RGB_val,...
                                       XYZ_val,...
                                       model,...
                                       matrix,...
                                       scale,...
                                       'targetcolorspace', targetcolorspace,...
                                       'metric', metrics);
% visualize final results
figureFullScreen('color', 'w');
ax1 = subplot(1,2,1);
colors2checker({xyz2rgb(XYZ_train), xyz2rgb(XYZ_train_pred)},...
               'layout', [10, 7],...
               'squaresize', 100,...
               'legend', {'Ground-truth', 'Predicted'},...
               'parent', ax1);
title('Training samples comparison');

ax2 = subplot(1,2,2);
colors2checker({xyz2rgb(XYZ_val), xyz2rgb(XYZ_val_pred)},...
               'layout', [10, 7],...
               'squaresize', 100,...
               'legend', {'Ground-truth', 'Predicted'},...
               'parent', ax2);
title('Validation samples comparison');
                        