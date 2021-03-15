Order of Functions or Scripts to use: 
1. stack2Images(workdir) - Converts stacks from a .lif sequence into organised '.png' images. It will process stacks in the interval given

2. MATLAB: deNoise(workdir) - Imports each image from step 1, denoise and export into folder structure.

3. images2Stack(workdir) - Imports denoised images from step 2, convert into single TIFF stack and export into folder structure.

4. imageRestore(workdir) - Imports denoised stacks from step 3, background substracted, anisotropic filtering applied, stacks exported into folder structure.

5. downFuse(workdir) - Import processed stacks from step 4, downsampling of each stack, fusing of all stacks into large fused volume, export fused volume to folder structure.

6. MATLAB: objectSegmentation(gridseg) - Object with desired geometric properties is segmented and concentration heatmap is generated at specified resolution (gridseg). Geometric properties must be changed by editing code in annotated section.
 gridseg = total number of segments in heatmap (default = 100)

Optional
7. MATLAB: timeAnalysis(seqnum) - Will use non-paired tests to measure significant changes accross time points, results exported as csv. A sufficient sample size and independent samples are nescessary for score reliability 
8. makeRois(workdir); - ROI data generated and exported to ROI file. File can be imported in Fiji or other software for data exploration.
