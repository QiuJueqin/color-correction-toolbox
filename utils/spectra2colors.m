function colors = spectra2colors(spectra, wavelengths, varargin)
%%
% SPECTRA2COLORS calculates XYZ or (linear) sRGB values given the spectral
% data.
%
% USAGE:
% colors = spectra2colors(spectra, wavelengths, 'param', value, ...);
%
% INPUTS:
% spectra:           spectral data as a N*W matrix, where N is the number
%                    of samples (surfaces) and W is the number of sampling
%                    wavelengths. It can be spectral radiance data where
%                    the spectral power distribution (spd) of the
%                    illuminant has been included, or spectral reflectance
%                    data where no illuminant info is included. If
%                    'spectra' is the spectral reflectance data, the user
%                    have to specify the illuminant (see 'spd' and
%                    'spdwavelengths' optional parameters below). See
%                    Examples below for additional notes.
% wavelengths:       a vector to specify the sampling points for 'spectra',
%                    s.t. length(wavelengths) == size(spectra, 2). If it is
%                    not given ([]), the default one, [380:interval:780]
%                    will be used, where interval is inferred from
%                    'spectra'.
%
% OPTIONAL PARAMETERS:
% includeilluminant: boolean value to denote whether the illuminant spd has
%                    been included in 'spectra'. This parameter can be
%                    false only when 'spd' is not empty. (default = true) 
% spd:               specify illuminant info when the 'spectra' contains
%                    only spectral reflectance data. Can be a numeric spd
%                    vector or a standard illuminant name. The spd will be
%                    automatically normalized such that the Y value of a
%                    perfect reflecting surface is equal to 1. So if it is
%                    a vector, you have no need to care about its
%                    amplitude. When 'spd' is given (no matter a name or a
%                    vector), 'includeilluminant' will be false.
%                    numeric vector | 'D65' | 'A' | 'E' | 'D50' | 'D55' |
%                    'D75' | 'F2' (or 'CWF') | 'F8' | 'F11' (or 'TL84')
%                    (default = [])
% spdwavelengths:    a vector to specify the sampling points for 'spd' if
%                    'spd' has been given, s.t. length(spdwavelengths) ==
%                    length(spd). If it is not given ([]), the default one,
%                    [380:interval:780] will be used, where interval is
%                    inferred from 'spd'. (default = [])
% observer:          specify the standard colorimetric observer functions
%                    when calculating XYZ values.
%                    '1931' (default) | '1964'
% output:            specify the color space for the output color responses.
%                    'XYZ' (default) | 'sRGB' (linear)
%
% OUTPUTS:
% colors:            XYZ or (linear) sRGB values corresponding to spectra
%
% EXAMPLES:
% 1. If 'spectra' is the spectral radiance data (usually measured by a
%    spectroradiometer, in W*m^(-2)*sr^(-1)*nm^(-1)), use
%    colors = 683 * spectra2colors(spectra, wavelengths);
%    to calculate the absolute XYZ values in cd*m^(-2).
%
% 2. If 'spectra' is the spectral reflectance data (usually measured by a
%    spectrophotometer, dimensionless unit, in range [0, 1] for normal
%    materials), use 
%    colors = spectra2colors(spectra, wavelengths,...
%                            'spd', spd,...
%                            'spdwavelengths', spdwavelengths);
%    or
%    colors = spectra2colors(spectra, wavelengths,...
%                            'spd', illuminant_name);
%    to calculate the normalized color responses within range [0, 1].
%
% Copyright
% Qiu Jueqin - Feb, 2019

% if the number of spectra is larger than MAX_SAMPLES_NUM, e.g., reshaped
% from a hyperspectral image, no interpolation will be performed to the
% input spectra, otherwise the conversion will be extremly slow
MAX_SAMPLES_NUM = 1E3;

global WAVELENGTH_RANGE WAVELENGTH_INTERVAL

% default wavelength range. Do NOT modify.
WAVELENGTH_RANGE = [380, 780];

% default wavelength interval. Can be modified (but not recommended).
% since the built-in illuminant spds and cmfs are sampled at 5nm interval,
% decreasing this values has no help in improving accuracy.
WAVELENGTH_INTERVAL = 5;

% parse and check the input parameters
param = parseInput(varargin{:});
param = paramCheck(param);

% check the input spectra
assert(ismatrix(spectra),...
       ['''spectra'' must be a NxW matrix where N is the number of samples ',...
        'and W is the number of wavelengths.']);
if iscolumn(spectra)
    spectra = spectra'; % each sample must be a row vector
end
W = size(spectra, 2); % number of wavelengths

% check the input wavelengths
if isempty(wavelengths)
    wavelengths = linspace(WAVELENGTH_RANGE(1), WAVELENGTH_RANGE(2), W);
    warning('''wavelengths'' is not given. Use default values [%.5G, %.5G, ... ,%.5G].',...
            wavelengths(1), wavelengths(2), wavelengths(end));
else
    assert(isvector(wavelengths), '''wavelengths'' must be a vector.');
    if iscolumn(wavelengths)
        wavelengths = wavelengths'; % wavelengths must be a row vector
    end
    assert(numel(wavelengths) == W,...
           'the lengths of ''spectra'' and ''wavelengths'' do not match.');
end

% CIE standard observer color matching functions
cmfs_wavelengths = 380 : 5 : 780;
switch param.observer
    case '1931'
        % from CIE tech report, already in standard normalized format
        cmfs = [0.001368,0.002236,0.004243,0.007650,0.014310,0.023190,0.043510,0.077630,0.134380,0.214770,0.283900,0.328500,0.348280,0.348060,0.336200,0.318700,0.290800,0.251100,0.195360,0.142100,0.095640,0.057950,0.032010,0.014700,0.004900,0.002400,0.009300,0.029100,0.063270,0.109600,0.165500,0.225750,0.290400,0.359700,0.433450,0.512050,0.594500,0.678400,0.762100,0.842500,0.916300,0.978600,1.026300,1.056700,1.062200,1.045600,1.002600,0.938400,0.854450,0.751400,0.642400,0.541900,0.447900,0.360800,0.283500,0.218700,0.164900,0.121200,0.087400,0.063600,0.046770,0.032900,0.022700,0.015840,0.011359,0.008111,0.005790,0.004109,0.002899,0.002049,0.001440,0.001000,0.000690,0.000476,0.000332,0.000235,0.000166,0.000117,0.000083,0.000059,0.000042;...
                0.000039,0.000064,0.000120,0.000217,0.000396,0.000640,0.001210,0.002180,0.004000,0.007300,0.011600,0.016840,0.023000,0.029800,0.038000,0.048000,0.060000,0.073900,0.090980,0.112600,0.139020,0.169300,0.208020,0.258600,0.323000,0.407300,0.503000,0.608200,0.710000,0.793200,0.862000,0.914850,0.954000,0.980300,0.994950,1.000000,0.995000,0.978600,0.952000,0.915400,0.870000,0.816300,0.757000,0.694900,0.631000,0.566800,0.503000,0.441200,0.381000,0.321000,0.265000,0.217000,0.175000,0.138200,0.107000,0.081600,0.061000,0.044580,0.032000,0.023200,0.017000,0.011920,0.008210,0.005723,0.004102,0.002929,0.002091,0.001484,0.001047,0.000740,0.000520,0.000361,0.000249,0.000172,0.000120,0.000085,0.000060,0.000042,0.000030,0.000021,0.000015;...
                0.006450,0.010550,0.020050,0.036210,0.067850,0.110200,0.207400,0.371300,0.645600,1.039050,1.385600,1.622960,1.747060,1.782600,1.772110,1.744100,1.669200,1.528100,1.287640,1.041900,0.812950,0.616200,0.465180,0.353300,0.272000,0.212300,0.158200,0.111700,0.078250,0.057250,0.042160,0.029840,0.020300,0.013400,0.008750,0.005750,0.003900,0.002750,0.002100,0.001800,0.001650,0.001400,0.001100,0.001000,0.000800,0.000600,0.000340,0.000240,0.000190,0.000100,0.000050,0.000030,0.000020,0.000010,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    case '1964'
        cmfs = [0.000160,0.000662,0.002362,0.007242,0.019110,0.043400,0.084736,0.140638,0.204492,0.264737,0.314679,0.357719,0.383734,0.386726,0.370702,0.342957,0.302273,0.254085,0.195618,0.132349,0.080507,0.041072,0.016172,0.005132,0.003816,0.015444,0.037465,0.071358,0.117749,0.172953,0.236491,0.304213,0.376772,0.451584,0.529826,0.616053,0.705224,0.793832,0.878655,0.951162,1.014160,1.074300,1.118520,1.134300,1.123990,1.089100,1.030480,0.950740,0.856297,0.754930,0.647467,0.535110,0.431567,0.343690,0.268329,0.204300,0.152568,0.112210,0.081261,0.057930,0.040851,0.028623,0.019941,0.013842,0.009577,0.006605,0.004553,0.003145,0.002175,0.001506,0.001045,0.000727,0.000508,0.000356,0.000251,0.000178,0.000126,0.000090,0.000065,0.000046,0.000033;...
                0.000017,0.000072,0.000253,0.000769,0.002004,0.004509,0.008756,0.014456,0.021391,0.029497,0.038676,0.049602,0.062077,0.074704,0.089456,0.106256,0.128201,0.152761,0.185190,0.219940,0.253589,0.297665,0.339133,0.395379,0.460777,0.531360,0.606741,0.685660,0.761757,0.823330,0.875211,0.923810,0.961988,0.982200,0.991761,0.999110,0.997340,0.982380,0.955552,0.915175,0.868934,0.825623,0.777405,0.720353,0.658341,0.593878,0.527963,0.461834,0.398057,0.339554,0.283493,0.228254,0.179828,0.140211,0.107633,0.081187,0.060281,0.044096,0.031800,0.022602,0.015905,0.011130,0.007749,0.005375,0.003718,0.002565,0.001768,0.001222,0.000846,0.000586,0.000407,0.000284,0.000199,0.000140,0.000098,0.000070,0.000050,0.000036,0.000025,0.000018,0.000013;...
                0.000705,0.002928,0.010482,0.032344,0.086011,0.197120,0.389366,0.656760,0.972542,1.282500,1.553480,1.798500,1.967280,2.027300,1.994800,1.900700,1.745370,1.554900,1.317560,1.030200,0.772125,0.570060,0.415254,0.302356,0.218502,0.159249,0.112044,0.082248,0.060709,0.043050,0.030451,0.020584,0.013676,0.007918,0.003988,0.001091,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    otherwise
        error('''%s'' is not a valid standard observer name. ''observer'' can only be ''1931'' or ''1964''.',...
              param.observer);
end

% multiply spd to spectra if it exists
if param.includeilluminant == true
    spd_wavelengths = wavelengths;
    spd = ones(1, W); % spd will be normalized later
else
    spd_wavelengths = param.spdwavelengths;
    spd = param.spd;
end

% the valid wavelength range for interpolation, which will be the UNION set
% of spectra wavelengths, spd wavelengths, and cmfs wavelengths to avoid
% extrapolation
interp_wavelengths = max([wavelengths(1), spd_wavelengths(1), cmfs_wavelengths(1)]) :...
                     WAVELENGTH_INTERVAL :...
                     min([wavelengths(end), spd_wavelengths(end), cmfs_wavelengths(end)]);

if interp_wavelengths(1) > wavelengths(1) || interp_wavelengths(end) < wavelengths(end)
    warning('values in spectra outside [%.5G, %.5G] wavelength range will be removed.',...
            interp_wavelengths(1),...
            interp_wavelengths(end));
end

% interpolation for spectra
% avoid unnecessary interpolation. interp1() is time-consuming when spectra
% is large
if ~isequal(wavelengths, interp_wavelengths)
    % determine whether to perform interpolation for the input spectra
    N = size(spectra, 1);
    if N > MAX_SAMPLES_NUM
        interp_wavelengths = wavelengths;
    else
        % spectra need to be transposed first before interpolation because it is a matrix
        spectra = interp1(wavelengths, spectra', interp_wavelengths, 'pchip')';
    end
    if iscolumn(spectra)
        spectra = spectra';
    end
end

if param.includeilluminant == false
    % interpolation for spd
    spd = interp1(spd_wavelengths, spd, interp_wavelengths, 'pchip');

    % normalize the spd
    spd = spd_normalize(interp_wavelengths, spd,...
                        cmfs_wavelengths, cmfs);

    spectra = spectra .* spd; % auto broadcasting
end

% interpolation for cmfs  
cmfs = interp1(cmfs_wavelengths, cmfs', interp_wavelengths, 'pchip')';

% matrix multiplication with CIE cmfs
xyz = WAVELENGTH_INTERVAL * spectra * cmfs';

switch lower(param.output)
    case 'xyz'
        colors = xyz;
    case 'srgb'
        colors = xyz2linsrgb(xyz);
    otherwise
        error('''output'' can only be ''XYZ'' or ''sRGB''.');
end

end


function spd = spd_normalize(spd_wavelengths, spd,...
                             cmfs_wavelengths, cmfs)
%%
% SPD_NORMALIZE normalizes illuminant spd such that the Y value is equal to
% 1 when observing a perfect reflecting surface
global WAVELENGTH_INTERVAL

assert(isrow(spd));
assert(size(cmfs, 1) == 3);
assert(numel(spd_wavelengths) == numel(spd));
assert(numel(cmfs_wavelengths) == size(cmfs, 2));

% cmfs will be temporarily resampled based on the wavelengths of spd
cmfs = interp1(cmfs_wavelengths, cmfs', spd_wavelengths, 'pchip')';
illuminant_xyz = WAVELENGTH_INTERVAL * spd * cmfs';

spd = spd / illuminant_xyz(2);
end


function param = parseInput(varargin)
%%
% parse inputs & return structure of parameters
parser = inputParser;
parser.PartialMatching = false;
parser.addParameter('includeilluminant', true, @(x)islogical(x));
parser.addParameter('observer', '1931', @(x)ischar(x));
parser.addParameter('spd', [], @(x)validateattributes(x, {'numeric', 'char'}, {}));
parser.addParameter('spdwavelengths', [], @(x)validateattributes(x, {'numeric', 'nonnegative'}, {}));
parser.addParameter('output', 'XYZ');
parser.parse(varargin{:});
param = parser.Results;
end


function param = paramCheck(param)
% check the input parameters
global WAVELENGTH_RANGE

if ~isempty(param.spd)
    param.includeilluminant = false;
end
if param.includeilluminant == false && isempty(param.spd)
    error('''spd'' must be given if set ''includeilluminant'' to false.');
end
if ~isempty(param.spdwavelengths) && isempty(param.spd)
    error('''spd'' must be given if set ''spdwavelengths'' is not empty.');
end
if strcmpi(param.output, 'sRGB')
    param.observer = '1931';
end

% determine the illuminant spd
if ischar(param.spd)
    % override user-input 'spdwavelengths' value if 'spd' is a illuminant name
    if ~isempty(param.spdwavelengths)
        warning('illuminant ''%s'' is specified. User input ''spdwavelengths'' will be invalid.',...
                param.spd);
    end
    param.spdwavelengths = 380 : 5: 780;
    % load spds for standard illuminant
    % note that all following spds have been normalized such that
    % w * (\int y(\lambda)I(\lambda) d\lambda) = 1,
    % where y(\lambda) is the y curve of CIE standard observer color
    % matching functions, I(\lambda) is the spd, and w is the wavelength
    % interval (5nm in current case).
    switch lower(param.spd)
        case 'd65'
            param.spd = [0.0047246683,0.0049459292,0.0051671905,0.0064965016,0.0078258133,0.0082387757,0.0086517381,0.0087439530,0.0088361679,0.0085172178,0.0081982687,0.0090585910,0.0099189123,0.010493507,0.011068101,0.011106384,0.011144668,0.011005326,0.010865984,0.010916463,0.010966942,0.010630707,0.010294473,0.010320460,0.010346449,0.010273172,0.010199895,0.010057677,0.0099154580,0.010052827,0.010190196,0.010034945,0.0098796925,0.0098628439,0.0098459953,0.0096546728,0.0094633494,0.0092900041,0.0091166580,0.0090909433,0.0090652294,0.0087292185,0.0083932066,0.0084558744,0.0085185422,0.0084993970,0.0084802518,0.0083904397,0.0083006267,0.0080920253,0.0078834230,0.0079029920,0.0079225600,0.0077488008,0.0075750411,0.0075840512,0.0075930618,0.0076908511,0.0077886400,0.0075996635,0.0074106869,0.0070053558,0.0066000246,0.0066894735,0.0067789219,0.0069085048,0.0070380871,0.0064348411,0.0058315955,0.0062235361,0.0066154771,0.0068616415,0.0071078059,0.0065637645,0.0060197231,0.0052068811,0.0043940395,0.0053589814,0.0063239238,0.0061619072,0.0059998911];
        case 'a'
            param.spd = [0.00090783456,0.0010102025,0.0011200961,0.0012377102,0.0013631745,0.0014966374,0.0016381914,0.0017879107,0.0019458695,0.0021120771,0.0022865613,0.0024692942,0.0026602386,0.0028593300,0.0030664848,0.0032815915,0.0035045207,0.0037351241,0.0039732349,0.0042186673,0.0044712182,0.0047306828,0.0049968115,0.0052693631,0.0055480776,0.0058326963,0.0061229318,0.0064184964,0.0067191031,0.0070244363,0.0073342090,0.0076480969,0.0079657845,0.0082869669,0.0086113187,0.0089385156,0.0092682522,0.0096002407,0.0099340836,0.010269501,0.010606217,0.010943952,0.011282336,0.011621091,0.011960031,0.012298693,0.012636892,0.012974441,0.013310879,0.013646111,0.013979862,0.014311850,0.014641892,0.014969710,0.015295211,0.015617932,0.015937965,0.016254939,0.016568761,0.016879156,0.017186027,0.017489284,0.017788649,0.018084029,0.018375330,0.018662460,0.018945143,0.019223375,0.019497160,0.019766217,0.020030547,0.020290058,0.020544657,0.020794343,0.021038933,0.021278517,0.021513004,0.021742301,0.021966500,0.022185415,0.022399049];
        case 'e'
            param.spd = ones(1, 81) / 106.856635;
        case 'd50'
            param.spd = [0.0023282624,0.0025844185,0.0028404763,0.0037648354,0.0046892925,0.0050321748,0.0053750565,0.0055427207,0.0057103843,0.0056052143,0.0054999460,0.0063092262,0.0071186046,0.0077098920,0.0083011799,0.0084614856,0.0086218901,0.0086580915,0.0086943908,0.0088725518,0.0090508116,0.0089013949,0.0087520769,0.0089313174,0.0091105578,0.0091531361,0.0091957143,0.0092204371,0.0092452578,0.0094819888,0.0097187199,0.0096549513,0.0095910840,0.0096656447,0.0097402055,0.0096300319,0.0095198583,0.0094122356,0.0093045142,0.0093609262,0.0094174352,0.0091597093,0.0089020822,0.0091017289,0.0093014734,0.0093769170,0.0094524594,0.0094417660,0.0094311703,0.0092732189,0.0091153653,0.0092649776,0.0094144922,0.0092628198,0.0091110487,0.0092314249,0.0093518021,0.0095811747,0.0098106461,0.0096265003,0.0094422558,0.0088824602,0.0083226655,0.0085239792,0.0087251961,0.0087862182,0.0088471426,0.0080835801,0.0073200171,0.0077797440,0.0082395691,0.0085285902,0.0088175144,0.0081341043,0.0074507929,0.0064727697,0.0054948446,0.0066963546,0.0078978641,0.0076764380,0.0074550118];
        case 'd55'
            param.spd = [0.0030960226,0.0033578498,0.0036196767,0.0047064424,0.0057931086,0.0061547691,0.0065164291,0.0066604787,0.0068044290,0.0066305385,0.0064566485,0.0072981431,0.0081395386,0.0087288227,0.0093182065,0.0094358847,0.0095536625,0.0095278863,0.0095020104,0.0096366415,0.0097713722,0.0095499940,0.0093285171,0.0094526391,0.0095766624,0.0095776543,0.0095786452,0.0095452359,0.0095118256,0.0097128805,0.0099139344,0.0098139029,0.0097137727,0.0097551132,0.0097965533,0.0096554784,0.0095145022,0.0093821511,0.0092498995,0.0092753777,0.0093007581,0.0090004643,0.0087001715,0.0088426350,0.0089849988,0.0090194996,0.0090539996,0.0090103783,0.0089668566,0.0087874141,0.0086080711,0.0086978916,0.0087877121,0.0086224461,0.0084571810,0.0085269753,0.0085968683,0.0087699657,0.0089430632,0.0087531125,0.0085631609,0.0080738096,0.0075843581,0.0077351495,0.0078858407,0.0079810144,0.0080761882,0.0073808250,0.0066855610,0.0071170153,0.0075484701,0.0078193182,0.0080901673,0.0074660853,0.0068420027,0.0059336880,0.0050252741,0.0061263158,0.0072272583,0.0070316563,0.0068360544];
        case 'd75'
            param.spd = [0.0062601734,0.0064135334,0.0065668938,0.0080675269,0.0095682852,0.010036109,0.010503808,0.010546519,0.010589105,0.010133645,0.0096783098,0.010528660,0.011379011,0.011933881,0.012488625,0.012458153,0.012427556,0.012191521,0.011955361,0.011931133,0.011906905,0.011483666,0.011060551,0.011004727,0.010948903,0.010813526,0.010678150,0.010441615,0.010205080,0.010289129,0.010373177,0.010178105,0.0099830329,0.0099180918,0.0098531507,0.0096231103,0.0093929451,0.0091871321,0.0089813201,0.0089155044,0.0088496897,0.0085108737,0.0081719318,0.0081829224,0.0081939120,0.0081429584,0.0080920048,0.0079719890,0.0078518484,0.0076249302,0.0073978868,0.0073830257,0.0073681641,0.0071978192,0.0070274742,0.0070051197,0.0069828900,0.0070345928,0.0070862956,0.0069055855,0.0067248750,0.0063620806,0.0059991609,0.0060567334,0.0061143059,0.0062549282,0.0063954252,0.0058492976,0.0053030448,0.0056694611,0.0060357526,0.0062664174,0.0064969575,0.0060026576,0.0055083581,0.0047561680,0.0040039783,0.0048841764,0.0057642497,0.0056220046,0.0054797591];
        case {'f2', 'cwf'}
            param.spd = [0.00080591254,0.0010108056,0.0012566772,0.0014684000,0.0023494400,0.010715905,0.0026294605,0.0025543331,0.0028616725,0.0031553525,0.0034558622,0.023890527,0.0080659548,0.0042822640,0.0045281355,0.0047330288,0.0049106027,0.0050540278,0.0051496448,0.0052042827,0.0052247718,0.0052042827,0.0052042827,0.0050881766,0.0049720705,0.0048832837,0.0048149861,0.0048081563,0.0048901136,0.0051018363,0.0054911328,0.0060648336,0.0068365969,0.016992461,0.011364733,0.0099646309,0.011036904,0.011993071,0.012717027,0.014663510,0.015565040,0.013174621,0.012744346,0.012109177,0.011296435,0.010388076,0.0094250785,0.0084415926,0.0074785952,0.0065907254,0.0057370043,0.0049993899,0.0043095830,0.0037085637,0.0031963312,0.0027455664,0.0023562696,0.0020216112,0.0017415907,0.0014957191,0.0012908260,0.0011200819,0.0010449544,0.00086738047,0.00075127441,0.00067614694,0.00060101954,0.00051906233,0.00046442417,0.00041661580,0.00038246697,0.00036880744,0.00034831814,0.00032099907,0.00032099907,0.00029368000,0.00031416930,0.00032099907,0.00027319070,0.00022538232,0.00018440372];
        case {'f11', 'tl84'}
            param.spd = [0.00062151480,0.00043027947,0.00031417230,0.00025270382,0.00088104844,0.0086602280,0.0010859434,0.0012225400,0.0016801389,0.0022743344,0.0030665949,0.023180453,0.0082845874,0.0047467337,0.0049106497,0.0048628412,0.0045896475,0.0041866875,0.0037290887,0.0032714899,0.0038656853,0.0097598312,0.010217430,0.0061263600,0.0032236811,0.0015913511,0.0010039854,0.00075128162,0.00060785515,0.00056687614,0.00080592028,0.0033466180,0.027039308,0.049748503,0.022272086,0.0051360345,0.0019328427,0.0013386472,0.0011405821,0.0030256161,0.0077040517,0.010080833,0.0086943768,0.0066522574,0.0050062677,0.0066385977,0.037748486,0.029081428,0.0090017198,0.0089880601,0.0083733751,0.0034900445,0.0014137754,0.0015981809,0.0024450801,0.0020557798,0.0016937986,0.0014615842,0.0010517943,0.00090836780,0.00099715556,0.0013249876,0.0013659666,0.00081957993,0.00092202745,0.0028002316,0.0038110467,0.0017142880,0.00038930046,0.00018440549,0.00015708615,0.00014342649,0.00016391599,0.00016391599,0.00013659666,0.00016391599,0.00021855465,0.00017757565,0.00010927732,8.1957995e-05,6.1468498e-05];
        case 'f8'
            param.spd = [0.00082646933,0.0010245488,0.0012362888,0.0014548592,0.0021652130,0.0089340648,0.0026160143,0.0023564622,0.0026365053,0.0030190037,0.0034766353,0.023291407,0.0084832637,0.0052456893,0.0058740792,0.0064614872,0.0069942526,0.0074040722,0.0077387579,0.0079983100,0.0081827296,0.0083125057,0.0083876392,0.0084149605,0.0084354514,0.0084969243,0.0085720578,0.0086608520,0.0087223249,0.0086881733,0.0086062094,0.0084900940,0.0083466573,0.019780621,0.011276866,0.0080529526,0.0080324616,0.0080392919,0.0080871042,0.0099791046,0.011003654,0.0084286211,0.0085583972,0.0086881733,0.0088247797,0.0089613860,0.0091116531,0.0092960717,0.0094736610,0.0096102674,0.0096990615,0.0096717402,0.0096512493,0.0097946860,0.0099039711,0.0098766498,0.0095624551,0.0085925488,0.0075065270,0.0068166642,0.0062975595,0.0058877398,0.0055120722,0.0050476100,0.0045831478,0.0042074802,0.0038454728,0.0034356534,0.0030463249,0.0027457906,0.0024998989,0.0022949891,0.0021105704,0.0019466425,0.0018100361,0.0017144115,0.0016187869,0.0014685198,0.0012909314,0.0010996823,0.00090160285];
        otherwise
            error('''%s'' is not a valid illuminant name. Only a numeric vector or following illuminants are supported:\n%s',...
                  param.spd, strjoin({'D65', 'A', 'E', 'D50', 'D55',...
                                      'D75', sprintf('''F2'' (or ''CWF'')'),...
                                      'F8', sprintf('''F11'' (or ''TL84'')')}, ' | '));
    end
elseif ~isempty(param.spd)
    assert(isvector(param.spd), '''spd'' must be a vector.');
    if iscolumn(param.spd)
        param.spd = param.spd'; % spd must be a row vector
    end
    W_spd = numel(param.spd); % number of wavelengths
    if isempty(param.spdwavelengths)
        param.spdwavelengths = linspace(WAVELENGTH_RANGE(1), WAVELENGTH_RANGE(2), W_spd);
        warning('''spdwavelengths'' is not given. Use default values [%.5G, %.5G, ... ,%.5G].',...
                param.spdwavelengths(1), param.spdwavelengths(2), param.spdwavelengths(end));
    else
        assert(isvector(param.spdwavelengths), '''spdwavelengths'' must be a vector.');
        if iscolumn(param.spdwavelengths)
            param.spdwavelengths = param.spdwavelengths'; % spdwavelengths must be a row vector
        end
        assert(numel(param.spdwavelengths) == W_spd,...
               'the lengths of ''spd'' and ''spdwavelengths'' do not match.');
    end
end
end

