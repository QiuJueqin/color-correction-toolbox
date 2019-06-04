function [predicted_responses, errs] = ccmvalidate(camera_responses,...
                                                   target_responses,...
                                                   model,...
                                                   matrix,...
                                                   scale,...
                                                   varargin)
% CCMVALIDATE converts the camera responses into the corrected responses,
% via a scaling factor and a color correction matrix, and then calculates
% the errors between the converted responses and the target responses.
%
% USAGE:
% [predicted_responses, err_val] = ccmvalidate(camera_responses,...
%                                              target_responses,...
%                                              model,...
%                                              matrix,...
%                                              scale,...
%                                              'param', value, ...);
%
% INPUTS:
% camera_responses:  Nx3 camera linear RGB responses to be validated, in
%                    the range 0-1, with darkness level subtracted. (can
%                    also be XYZ responses in some particular cases)
% target_responses:  Nx3 target linear RGB/XYZ responses to be validated,
%                    in the range 0-1.
% model:             color correction model, based on which the camera
%                    responses will be expanded.
%                    'linear3x3' (default) | 'root6x3' | 'root13x3' |
%                    'poly4x3' | 'poly6x3' | 'poly7x3' | 'poly9x3'
% matrix:            color correction matrix, which should match 'model'.
% scale:             the scaling factor. Camera responses will be first
%                    scaled by this factor and then be expanded and
%                    multiplied. (default = 1)
%
% OPTIONAL PARAMETERS:
% omitlightness:     boolean value. Set to true to omit lightness component
%                    when calculating the color difference metrics. This
%                    option will be useful if the camera responses are in a
%                    different range from the target responses due to the
%                    exposure difference. (default = false)
% targetcolorspace:  specify the color space for the target responses.
%                    'sRGB' (default, must be linear) | 'XYZ'
% observer:          specify the standard colorimetric observer functions
%                    when converting XYZ to L*a*b* or vice versa.
%                    '1931' (default) | '1964'
% refilluminant:     specify the reference illuminant when converting XYZ
%                    to L*a*b* or vice versa.
%                    'A' | 'C' | 'D50' | 'D55' | 'D65' (default) |
%                    'D75' | 'F2' | 'F11'
% metric:            color difference metrics to be evaluated. It should be
%                    a char or a cell containing one or more of following
%                    metrics.
%                    'mse' | 'ciede00' | 'ciede94' | 'ciedelab' | 'cmcde'
%                    (default = {'ciede00', 'ciedelab'})
%
% OUTPUTS:
% predicted_responses:  the color corrected responses predicted by 'scale'
%                       and 'matrix', i.e., predicted_responses =
%                       (scale * expanded_camera_responses) * matrix
% errs:              a structure array containing color differences
%                    on validation sample specified by 'metric'
%
% Copyright
% Qiu Jueqin - Feb, 2019

% parse and check the input parameters 
param = parseInput(varargin{:});
param = paramCheck(param);

% check the inputs
assert(isequal(size(camera_responses), size(target_responses)),...
       'The numbers of test and target samples do not match.');
assert(size(camera_responses, 2) == 3 && size(target_responses, 2) == 3,...
       'Both test and target responses must be Nx3 matrices.');
assert(max(camera_responses(:)) <= 1 && min(camera_responses(:)) >= 0,...
       'Test responses must be in the range of [0, 1]. Normalize them before running validation.');
assert(max(target_responses(:)) <= 1 && min(target_responses(:)) >= 0,...
       'Target responses must be in the range of [0, 1]. Normalize them before running validation.');

% color correction
predicted_responses = ccmapply(camera_responses,...
                               model,...
                               matrix,...
                               scale);
                     
% obs will be used to determine the condition for the conversion between
% XYZ values and L*a*b* values. See lab2xyz_.m and xyz2lab_.m for details.
switch param.observer
    case '1931'
        obs = [lower(param.refilluminant), '_31'];
    case '1964'
        obs = [lower(param.refilluminant), '_64'];
end

% validation
switch lower(param.targetcolorspace)
	case 'srgb'
        target_xyz = linsrgb2xyz(target_responses);
        target_lab = xyz2lab_(100*target_xyz, obs);
        predicted_xyz = linsrgb2xyz(predicted_responses);
        predicted_lab = xyz2lab_(100*predicted_xyz, obs);        
    case 'xyz'
        target_lab = xyz2lab_(100*target_responses, obs);
        predicted_lab = xyz2lab_(100*predicted_responses, obs);
end

disp('# Color correction validation results:');
disp('=================================================================');
for i = 1:numel(param.metric)
    switch lower(param.metric{i})
        case 'mse'
            errs.(param.metric{i}) = mean((predicted_responses - target_responses).^2, 2);
        otherwise
            lossfun = eval(['@', param.metric{i}]); % metric handle
            errs.(param.metric{i}) = lossfun(predicted_lab,...
                                             target_lab,...
                                             param.omitlightness);
    end
	fprintf('%s errors: %.4G (avg), %.4G (med), %.4G (max, #%d)\n',...
            param.metric{i},...
            mean(errs.(param.metric{i})),...
            median(errs.(param.metric{i})),...
            max(errs.(param.metric{i})),...
            find(errs.(param.metric{i}) == max(errs.(param.metric{i}))));
end
if param.omitlightness == true
    disp('# (lightness component has been omitted)');
end
disp('=================================================================');
end


function param = parseInput(varargin)
% parse inputs & return structure of parameters
parser = inputParser;
parser.addParameter('metric', {'ciede00', 'ciedelab'}, @(x)validateattributes(x, {'char', 'cell'}, {})); % for evaluation
parser.addParameter('observer', '1931', @(x)ischar(x));
parser.addParameter('omitlightness', false, @(x)islogical(x));
parser.addParameter('refilluminant', 'D65', @(x)ischar(x));
parser.addParameter('targetcolorspace', 'sRGB');
parser.parse(varargin{:});
param = parser.Results;
end

function param = paramCheck(param)
% check the parameters

% check the metrics
metrics_list = {'mse', 'ciede00', 'ciede94', 'ciedelab', 'cmcde'};
if isempty(param.metric)
    param.metric = {'ciede00', 'ciedelab'};
end
if ~iscell(param.metric)
    param.metric = {param.metric};
end
for i = 1:numel(param.metric)
    if ~ismember(lower(param.metric{i}), metrics_list)
        error('%s is not a valid metric. Only following metrics are supported:\n%s',...
              param.metric{i}, strjoin(metrics_list, ' | '));
    end
end

% check the reference illuminants
refilluminants_list = {'A', 'C', 'D50', 'D55', 'D65', 'D75', 'F2', 'F11'};
if ~ismember(upper(param.refilluminant), refilluminants_list)
    error('%s is not a valid reference illuminant. Only following illuminants are supported:\n%s',...
          param.refilluminants, strjoin(refilluminants_list, ' | '));
end

% check the standard observer
stdobserver_list = {'1931', '1964'};
if ~ismember(upper(param.observer), stdobserver_list)
    error('%s is not a valid standard observer function. Only following observers are supported:\n%s',...
          param.observer, strjoin(stdobserver_list, ' | '));
end

end
