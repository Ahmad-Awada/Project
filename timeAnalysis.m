%USAGE          : timeAnalysis(seqnum)
%-seqnum        - Number of sequences/time points being analyzed.
%-                Must be a positive integer.
%-
%EXAMPLE        : timeAnalysis(3)
%-
function timeAnalysis(seqnum);
%Define heatmap grid size if argument is not provided 
if ~exist('seqnum', 'var')
    seqnum = input('You did not input an argument for the number of time points being measured: ');
end

while seqnum < 2
    seqnum = input('You must input a valid number of time points (n > 2): ');
end

%Create a cell array for the directory strings of each sequence
workdir = cell([1, seqnum]);
findir = cell([1, seqnum]);
fusepath = cell([1, seqnum]);

%create a cell array for each sequence
C = cell([1, seqnum]);


for i = 1:seqnum
    %Create an array with the directory strings of each sequence
    workdir{1, i} = uigetdir([], ['Select the workspace directory for sequence ', num2str(i), ' in your time series']);
    findir{1, i} = [workdir{1, i}, '/Final Outputs/'];
    fusepath{1, i} = [findir{1, i}, 'Fused and flattened.png'];
    f = imread(fusepath{1, i});
    C{1, i} = f;
end

%Get outputs for each image registered
moving_reg = cell([1, seqnum]);
R_reg = cell([1, seqnum]);
tform = cell([1, seqnum]);

%Generate initial optmizer
[optimizer,metric] = imregconfig('monomodal');


for i = 1:seqnum
    %Stops time point 1 from registering to itself (save computation time)
    if i == 1
        tform{1, i} = affine2d;
    else
        [moving_reg{1, i}, R_reg{1, i}] = imregister(C{1, i}, C{1, 1}, 'translation', optimizer, metric);
        tform{1, i} = imregtform(C{1, i}, C{1, 1}, 'translation', optimizer, metric);
    end
end

%Create variables
norm0 = cell([1, seqnum]);
norm = 1:seqnum;
1:seqnum;
arr = cell([1, seqnum]);
meant = 1:seqnum;
sigval = 1:seqnum;

for i = 1:seqnum
    %Open table
    restablepath = [findir{1, i}, 'Results.csv'];
    restable = readtable(restablepath);
    %Calculate 2D dot product for each value in the table
    arr0 = 1:height(restable);
    
    %Add geometric translation obtained from affine matrix (tform)
    arr0(:) = restable.x(:) + tform{1, i}.T(3, 1) + restable.y(:) + tform{1, i}.T(3, 2);
    arr{1, i} = arr0;
    norm0{1, i} = normalitytest(arr0);
    norm(i) = norm0(7, 2);  
end

%Make 1D array to assign groups with unequal sample size

o = cellfun(@length, arr);

catarr = horzcat(arr{1, :});
satarr = zeros(1, sum(o));

for i = 1:seqnum
    if i == 1
        satarr(1:o(i)) = i;
    else
        ipos = sum(o(1:i-1))+1;
        fpos = sum(o(1:i));
        satarr(ipos:fpos) = i;
    end
end

%Checks if any sample is normally distributed
tempcount0 = length(find(norm <= 0.05));
var = vartestn(catarr, satarr);

%Checks if samples have equal variance
tempcount0 = tempcount0 + length(find(var <= 0.05));

%Change to "if tempcount0 == -1" to use only non-parametric test
if tempcount0 == 0
    %parametric
    if seqnum == 2
        [h, p] = ttest2(arr{1, 1}, arr{1, 2},'Vartype','unequal');
    else
        [p,tbl,stats] = ranovan(catarr,satarr);
    end            
else  
    %non-parametric
    if seqnum ==2
        p = ranksum(arr{1, 1}, arr{1, 2});
    else
        [p,tbl,stats] = kruskalwallis(catarr, satarr);
    end           
end

if exist('stats', 'var')
    [results, means, graph, gnames] = multcompare(stats,'CType','bonferroni');
end

%Create cell array for multiple comparaison data
header0 = {'Reference_Sample' 'Compared_Sample' 'Low' 'Ref_minus_Target_Mean' 'High' 'p_value'};
results0 = [header0; num2cell(results)];

%Fix empty cells
temp = cellfun('isempty', results0);
results0(temp) = {NaN};

%Convert to table
results0 = cell2table(results0(2:end, :), 'VariableNames', results0(1, :));

%Fix cell array for multiple comparaison data
tbl(1, 5) =  {'Chi_sq'};
tbl(1, 6) =  {'p_value'};

%Fix empty cells
temp = cellfun('isempty', tbl);
tbl(temp) = {NaN};

%Convert to table
tbl = cell2table(tbl(2:end, 2:end), 'VariableNames', tbl(1, 2:end), 'RowNames', tbl(2:end,1));


%Create pathnames in stack/time point 1 
resnametest = [findir{1, 1}, 'Time Series Hypothesis Test.csv'];
resnamemult = [findir{1, 1}, 'Time Series Multiple Comparison Test.csv'];
imname = [findir{1, 1}, 'Multiple comparison Graph.png'];

%Export data
writetable(tbl, resnametest);
writetable(results0, resnamemult);
saveas(graph, imname);
end



