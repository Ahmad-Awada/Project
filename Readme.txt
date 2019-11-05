1. Copy all the files in './Fiji/Plugins' to your Fiji plugins folder
2. Copy the './MATLAB' Files directory to your MATLAB environment
3. In MATLAB, type 'installMatImage' in the command window (Make sure your scripts are in your MATLAB environment)
4. Exit MATLAB
5. Launch Fiji
6. Select 'Plugins>New>Macro'
7. In the Macro window, select 'File>Open...' or press 'ctrl+o'
8. Locate '.\Fiji Files\Main Script 4.ijm' and open it
9. Scroll all the way to the bottom of the code and read the instructions

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