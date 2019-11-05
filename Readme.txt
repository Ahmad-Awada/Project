Order of Functions or Scripts to use: 
1. stack2Images(workdir) - Converts stacks from a .lif sequence into organised '.png' images. It will process stacks in the interval given

2. MATLAB: deNoise(workdir)

3. images2Stack(workdir)

4. imageRestore(workdir)

5. downFuse(workdir) 

6. MATLAB: objectSegmentation(gridseg)
 gridseg = total number of segments in heatmap (default = 100)

7. MATLAB: timeAnalysis(seqnum)

This script will use non-paired tests to measure significant changes accross time points. 
So the results are invalid, but it may be used for data exploration or if an independent sequence is being compared.

-8 (optional)

makeRois(workdir);
