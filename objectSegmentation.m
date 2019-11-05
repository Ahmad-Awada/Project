%USAGE          : objectSegmentation(gridseg)
%EXAMPLE        : objectSegmentation(100)
%
%Arguments
% -gridseg      - Minimum number of segments in the density map. 
%                 The closest value to above gridseg that can be
%                 used to partition the heatmap into whole x and y 
%                 integer sizes will be used. 
%               - Must be a positive integer.
%
%Note that all values are based off volumes that have been downscaled by 0.75 in each of X and Y axis.
%This means that objects will also be downscaled.
%Example: 1024x1024x30 -> 768x768x30 
%
%To change the initial volume filter parameters to speed up computation or else skip to line 66
%To change the volume filter parameters at a later stage or other morphological parameters skip to line 134

function objectSegmentation(gridseg);
%function objectSegmentation(gridseg)
workdir = uigetdir([], 'Select your initial workspace directory');
    
%Define heatmap grid size if argument is not provided 
if ~exist('gridseg', 'var')
    gridseg = 20;
else
    isint = isa(gridseg,'double');
    if isint == 0 || floor(gridseg) ~= gridseg
        disp('gridseg argument must be a positive integer (e.g. 100)')
        return
    end
end

%Define the fused slice images directory and their extention
findir = [workdir, '\Final Outputs\'];
fusedir = [findir, 'Fused\s'];
ext = '.png';

%Get number of slices
temp = dir([fusedir, '*.png']);
imgnum = length(temp);

%Create an empty cell array with 1 row and 50 columns
C = cell([1 imgnum]);

disp('Generating Object Stack...')

for i = 1:1:imgnum
    %Make a new name for image 'i'
    newname = strcat(fusedir ,num2str(i), ext);
    
    %Read image and change from [0-255] to [0-1]
    f = im2bw(rgb2gray(imread(newname)));
    
    %insert image matrix in cell 'i'
    C{1, i} = f;
end

%Concatenate 2D image matrices into 3D array
imstack = cat(3, C{1:imgnum});

%Get dimensions
[ysize, xsize, zsize] = size(imstack);
minn = min([ysize, xsize]);
maxn = max([ysize, xsize]);

%CHANGE Linterval AND Hinterval to the lower and upper intervals of your object
%Delete objects outside that volume range
Linterval = 15;
Hinterval = 49;
imstack = xor(bwareaopen(imstack, Linterval, 6),  bwareaopen(imstack, Hinterval, 6));

%Find connected componnents
disp('Detecting connected components...');
CC = bwconncomp(imstack,6);

%Create a label matrix
disp('Labelling connected components...');
L = labelmatrix(CC);

%Analyze 3D objects
disp('Analysing morphology of labelled Objects...');
stats = regionprops3(L, 'BoundingBox', 'Centroid', 'ConvexVolume', 'EquivDiameter', 'Extent', 'PrincipalAxisLength', 'Solidity', 'SurfaceArea', 'Volume');

%Calculate and add surface area to volume ratio to the table
stats.SVR = stats.Volume./stats.SurfaceArea;

%Calculate and add 'sphericity' to the table
stats.Sphericity = (36*pi).*(stats.Volume.^2./stats.SurfaceArea.^3);

%Split merged headers
stats = splitvars(stats);

%Change centroid coordinate name to x, y and z
stats.Properties.VariableNames{'Centroid_1'} = 'x';
stats.Properties.VariableNames{'Centroid_2'} = 'y';
stats.Properties.VariableNames{'Centroid_3'} = 'z';

stats.BoundingBox_1 = [];
stats.BoundingBox_2 = [];
stats.BoundingBox_3 = [];
stats.BoundingBox_6 = [];
stats.PrincipalAxisLength_3 = [];

%Calculate centre of mass
n = height(stats);
xc = mean(stats.x);
yc = mean(stats.y);
zc = mean(stats.z);

%Add to array and label
com = table(xc, yc, zc, 'VariableNames', {'xc','yc','zc'});

%Export centre of mass coordinates
compath = [findir, 'Centre of Mass.csv'];
writetable(com, compath);

%Remove '%' for the next 3 lines to round coordinates from subpixel to pixel accuracy 
%stats.x = round(stats.x);
%stats.y = round(stats.y);
%stats.z = round(stats.z);

%Calculate and add surface area to volume ratio to the table
stats.SVR = stats.Volume./stats.SurfaceArea;

%Calculate and add 'sphericity' to the table
stats.Sphericity = (36*pi).*(stats.Volume.^2./stats.SurfaceArea.^3);

%Calculate BoundingBox XY area and PrincipalAxisLength XY area
stats.BoundingBox_4 = stats.BoundingBox_4.*stats.BoundingBox_5;
stats.Properties.VariableNames{'BoundingBox_4'} = 'BBarea';
stats.PrincipalAxisLength_1 = stats.PrincipalAxisLength_1.*stats.PrincipalAxisLength_2;
stats.Properties.VariableNames{'PrincipalAxisLength_1'} = 'PParea';

%Apply mathematical morphology filter after indexing 
%CHANGE VALUES IN THIS BLOCK FOR CUSTOM FILTERING. 
%(keep in mind the sequence is downscaled by 0.75 and those values are based on pixel units)
%Use Inf and -Inf to remove max or min limit respectively
Z_min = 7; %Default: 7
Volume_min = 16; %Default: 16
Volume_max = 26; %Default: 26
Solidity_min = 0.75; %Default: 0.75
Solidity_max = 1.98; %Default: 1.98
ConvexVolume_min = 8; %Default: 8
ConvexVolume_max = 28; %Default: 28
SurfaceArea_min = 27.5; %Default: 27.5
SurfaceArea_max = 93.1; %Default: 93.1
SVR_min = 0.44; %Default: 0.44
SVR_max = 0.609; %Default: 0.609
Sphericity_min = 0.574; %Default: 0.574 
Sphericity_max = 1.195; %Default: 1.195
Extent_min = 0.333; %Default: 0.333
Extent_max = 0.708; %Default: 0.708
PrincipalaxisLengthXY_min = 10; %(Principal axis length in X times by principal axis length in Y) Default: 10
PrincipalaxisLengthXY_max = 22.5; %(Principal axis length in X times by principal axis length in Y) Default: 22.5
BoundingBoxXYArea_min = 8; %Default: 8
BoundingBoxXYArea_max = 24; %Default: 24
EquivDiameter_min = 3.06; %Default: 3.06
EquivDiameter_max = 3.72; %Default: 3.72

disp('Applying morphological filter...');
indall = stats.z(:) > Z_min & stats.Volume(:) > Volume_min & stats.Volume(:) < Volume_max &...
    stats.Solidity(:) > Solidity_min & stats.Solidity(:) < Solidity_max & stats.ConvexVolume(:) > ConvexVolume_min &...
    stats.ConvexVolume(:) < ConvexVolume_max & stats.SurfaceArea(:) > SurfaceArea_min & stats.SurfaceArea(:) < SurfaceArea_max &...
    stats.SVR(:) > SVR_min & stats.SVR(:) < SVR_max & stats.Sphericity(:) > Sphericity_min &...
    stats.Sphericity(:) < Sphericity_max & stats.Extent(:) > Extent_min & stats.Extent(:) < Extent_max &...
    stats.PParea(:) > PrincipalaxisLengthXY_min & stats.PParea(:) < PrincipalaxisLengthXY_max & stats.BBarea(:) > BoundingBoxXYArea_min &...
    stats.BBarea(:) < BoundingBoxXYArea_max & stats.EquivDiameter(:) > EquivDiameter_min & stats.EquivDiameter(:) < EquivDiameter_max;

tempname = stats.Properties.VariableNames;

stats = table2array(stats);
stats(~indall, :) = [];
stats = array2table(stats, 'VariableNames', tempname);

%Re-order headers
stats = movevars(stats,'x','After','Sphericity');
stats = movevars(stats,'y','After','x');
stats = movevars(stats,'z','After','y');

disp('Exporting results table...');
%Save table
statsdir = [findir, 'Results.csv'];
writetable(stats, statsdir);

disp('Generating heatmap...');
minn = min([ysize, xsize]);
maxn = max([ysize, xsize]);

divmin = divisors(minn);
divmax = divisors(maxn);

%Find biggest common denominator
n_count = length(divmin);
isit = ismember(divmin(n_count), divmax);

while ismember(divmin(n_count), divmax) == 0
    n_count = n_count-1;
end

commondiv = divmin(n_count);

%Define the ratio of x to y pixels on the heatmap
xfactor = (xsize/commondiv);
yfactor = (ysize/commondiv);
xyfactor = xfactor + yfactor;

it = 1;
xgrid = 0.1;
ygrid = 0.1;

%Define the size of X and Y pixels for the heatmap
while floor(xgrid) ~= xgrid || floor(ygrid) ~= ygrid || gridnew<gridseg
    xgrid = xfactor * it;
    ygrid = yfactor * it;
    gridseg = gridseg + 1;
    gridnew = xgrid*ygrid;
    it = it+1;
end

maptable = zeros(ygrid,xgrid);

%Size of one heatmap pixel height (Y) in image pixels
oney = ysize/ygrid;

%Size of one heatmap pixel width (X) in image pixels
onex = xsize/xgrid;

for ix = 1:xgrid
    %Create margin for each segment in X
    xmax = onex*(ix);
    xmin = onex*(ix-1);
    
    
    for iy = 1:ygrid
        %Create a new counter
        o = 0;

        %Create margin for each segment in Y
        ymax = oney*(iy);
        ymin = oney*(iy-1);
    	
        %Index through results table picking values within ranges
        o = length(find(stats.x >= xmin & stats.x < xmax & stats.y >= ymin & stats.y < ymax));
        maptable(iy, ix) = o;
    end
end

disp('Exporting heatmap data...');
heatmap(maptable,'Colormap',copper);
heatmapfig = gcf;
heatmapfigname = [findir, 'Heatmap.png'];
saveas(heatmapfig,heatmapfigname, 'png');
tablename = [findir, 'Heatmap.csv'];
csvwrite(tablename, maptable);

disp('Object segmentation completed.');
end
