function currentTime() {
	timenow0= getTime();
	timenow1= round((timenow0 - start)/1000);
	return timenow1;
}

function stack2Images(workdir){
	//User prompts
	stackdir = File.openDialog("Select a stack to process (e.g. ./distal003b.lif)");
	series_first0 = getNumber("Input the number of the first stack being processed", 1);
	series_last0 = getNumber("Input the number of the final stack being processed", 25);
	t_c = getNumber("Input the total number of channels:", 3);
    g_c = getNumber("Input the number of the channel being measured? (the first channel is considered 1 and not 0)", 3);
	rawdir = workdir + "Raw/";
	ser1 = series_first0 - 1;
	
	start = getTime();
	
	//Create counter
	o=0;
	File.makeDirectory(rawdir);

	//Loop to process all series in a file
	for (i=ser1; i<series_last0; i++){
	
		//Import first stack
	    IJ.log(currentTime() + "s - Stack "+ i+1 + "/" + series_last0 +": Importing...");
		run("Bio-Formats Importer", "open=[" + stackdir + "] autoscale color_mode=Colorized rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT series_" + i+1);
	    
	    //Close all channels except Citrine
	    if (t_c == 3) {
	        close('*' + "C=" + g_c-t_c+1);
	        close('*' + "C=" + g_c-t_c);
	        close('*' + "C=" + g_c);
	        close('*' + "C=" + g_c+t_c-2);
		}
		if (t_c == 2) {
		    close('*' + "C=" + g_c-t_c);
		    close('*' + "C=" + g_c);
		}
	
		//ID windows and add series identifier
		title = getTitle();
		id = getImageID();
	    if (i<9) {
	    	rename(title + " s0" + i+1);
	    }
	    else {
	    	rename(title + " s" + i+1);
	    }
	    title_new = getTitle();
		slice_n = nSlices;
	    run("Stack to Images");
	    IJ.log(currentTime() + "s - Stack "+ i+1 + "/" + series_last0 +": Saving stack as images...");
	    for (j=0; j<slice_n; j++) { //would be faster if it stack->image all at once
	    	subdir= rawdir + 's' + series_first0 + o; 
	    	File.makeDirectory(subdir);
	    	run("8-bit");
	    	saveAs("png", subdir+ '/' + slice_n-j);
	    	close();
	    }
	    o = o+1;
	    IJ.log(currentTime() + "s - Stack "+ i+1 + "/" + series_last0 +": Complete.");
	}
}

function images2Stack(workdir){
	//User prompts
	series_first1 = getNumber("Input the number of the first stack being processed: ", 1);
	series_last1 = getNumber("Input the number of the last stack being processed: ", 25);
	imageloc = workdir + "Denoised/";
	
	start = getTime();

	//Count the number of images to stack
    slice_n1 = 0;
    flist = getFileList(imageloc + "s1/");
    for (i=0; i<flist.length; i++) {
        if (endsWith(flist[i], ".png")) {
    		slice_n1 = slice_n1 + 1;
        }
    }
	
	for (j=series_first1-1; j<series_last1; j++){
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last1 +": Stacking images...");
		for (i=0; i<slice_n1; i++){
			open(imageloc + "s" + j+1 + "/" + i+1 +  ".png");
		}
		
		subdir1 = workdir + "Denoised/Denoised Stacks/";
		File.makeDirectory(subdir1);
		run("Images to Stack");
		run("Green");
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last1 +": Saving stack...");
		if (j+1>9){
			saveAs("tiff", subdir1 + "s" + j+1);
		}
		else{
			saveAs("tiff", subdir1 + "s0" + j+1);
		}
		close();
	}
}

function imageRestore(workdir) {
	//User Prompt
	series_first = getNumber("Input_ the number of the first stack you would like to process: ", 1);
	series_last = getNumber("Input_ the number of the last stack you would like to process: ", 25);

	//Get initial time
	start = getTime();

	//Define directory containing denoised stacks
	stackdir = workdir + "Denoised/Denoised Stacks/";

	//Create counter
	o = 0;

	for (j=series_first-1; j<series_last; j++){
		if (j+1>9){
			open(stackdir+"s"+series_first + o+".tif");
		}
		else {
			open(stackdir+"s0"+series_first + o+".tif");
		}
		//Get image info
		num = nSlices;
		wind = getImageID();
	    title = getTitle();
	    
	    //Background substraction
	    IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Subtracting background...");
	    run("Subtract Background...", "rolling=18 stack");

	    //Anisotropic filter
	    IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Applying anisotropic filter...");
		for (i=0; i<num; i++){
		    selectImage(wind);
		    setSlice(i+1);
		    //Initiates anisotropic diffusion with 25 iterations. You can increase iterations below for better quality but slower computation.
		    run("Anisotropic Diffusion...", "picture=" +title+ " iterations=25 k=5 lambda=0.20 big"); 
		    rename(i+1);
	   }
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Re-stacking...");
		run("Images to Stack");
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Applying median filter...");
		run("Median...", "radius=1 stack");
		setSlice(10);
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Registering stack...");
		run("StackReg", "transformation=Affine");
		run("Green");
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Saving processed stack...");
		//saves processed stack
		findir = workdir + "/Final Outputs/";
		newdir2 = findir + "Processed Stacks/";
		File.makeDirectory(findir);
		File.makeDirectory(newdir2);
		
		//Correct file number formatting
		if (j+1>9){
			processedpath = newdir2 + "s" + series_first + o+ ".tif";
		}
		else {
			processedpath = newdir2 + "s0" + series_first + o+ ".tif";
		}
		
		//Save and close
		saveAs("tiff", processedpath); 
		close();
		selectImage(wind);
		close();
		IJ.log(currentTime() + "s - Stack "+ j+1 + "/" + series_last +": Completed");
		o=o+1;
	}
}

function downFuse(workdir){
	//Close all images
	while (nImages>0) { 
		selectImage(nImages); 
		close(); 
    } 
      
	//User prompts
	Dialog.create("Define Grid Size");
	Dialog.setInsets(10,20,0);
	Dialog.addMessage("If the last row of your grid does not make a square, choose a grid size bigger than your sequence and black volumes will fill the empty space you can still chose a square.");
	Dialog.addNumber("Input the width of your sequence in stacks/tiles (X): ", 5);
	Dialog.addNumber("Input the width of your sequence in stacks/tiles (Y): ", 5);
	Dialog.show();
	stacknx = Dialog.getNumber();
	stackny = Dialog.getNumber();
	
	//Get workspace directory name
	workdirname = File.getName(workdir);
	
	//Changing the downsize value will render the morphological filter useless. This can be done if you wish to change the morphological conditions in "morphDetection()"
	downsize = 0.75;

	//Get initial time
	start = getTime();

	//Set initial max reslice value
	reslice = 9999999;
	
	//Define directories
	findir = workdir + "/Final Outputs/";
	pathdir = workdir + "/Final Outputs/Processed Stacks/";

	//Sequence stacks expected in sequence
    stackn = stacknx*stackny;
    
    //Actual number of stacks in folder
    flist = getFileList(pathdir);
    actualstackn = 0;
    for (i=0; i<flist.length; i++) {
        if (endsWith(flist[i], ".tif")) {
    		actualstackn = actualstackn + 1;
        }
    }
	

	for (i = 0; i < actualstackn; i++) {
	    if (i<9) {
	        open(pathdir + "s0" + i+1 + ".tif");
	    }
	    else {
	    	open(pathdir + "s" + i+1 + ".tif");
	    }

	    xsize = getWidth();
	    ysize = getHeight();
	    wind1 = getImageID();
		
	    if (nSlices < reslice) {
	    	reslice = nSlices;
	    }

	    IJ.log(currentTime() + "s - Stack "+ i+1 + "/" + stackn +": Resizing...");
	    //resize by given factor
	    run("Resize ", "sizex="+ xsize*downsize +" sizey="+ ysize*downsize +" method=Least-Squares interpolation=Cubic unitpixelx=true unitpixely=true"); 
	    wind2 = getImageID();
	    selectImage(wind1);
	    close();
	    selectImage(wind2);

		//Save each downsampled and non-binary stack in a temporary directory
		IJ.log(currentTime() + "s - Saving each downsampled and non-binary stack in a temporary directory...");
	    newdir0 = findir + "/temp/";
	    File.makeDirectory(newdir0);
		if (i<9) {
	        saveAs("tiff", newdir0+ "s0" + i+1 +".tif");
	    }
	    else {
	    	saveAs("tiff", newdir0+ "s" + i+1 +".tif");
	    }

		//Convert each stack to binary
		run("Convert to Mask", "method=Otsu background=Dark calculate black");

	    //Save each downsampled and binary stack
	    IJ.log(currentTime() + "s - Stack "+ i+1 + "/" + stackn +": Saving downsampled stack...");
	    newdir = findir + "/Processed Downsampled Stacks/";
	    File.makeDirectory(newdir);
		if (i<9) {
	        saveAs("tiff", newdir+ "s0" + i+1 +".tif");
	    }
	    else {
	    	saveAs("tiff", newdir+ "s" + i+1 +".tif");
	    }
	    close();
	}
	
	//Create empty volumes. (Change " black" to " white" if your background is white)
	if (actualstackn < stackn) {
		diff = stackn - actualstackn;
		for (i=0; i<diff; i++) {
			fnum = actualstackn + i+1;
			
			if (fnum < 10) {
				blankname = "s0" + fnum;
			}
			else {
				blankname = "s" + fnum;
			}
			
			newImage(fnum, "8-bit black", xsize*downsize, ysize*downsize, reslice);
			saveAs("Tiff", newdir0 + blankname + ".tif");
			saveAs("Tiff", newdir + blankname + ".tif");
			close();
		}
	}
	
	//Stitch, apply z-projection and save the non-binary sequence for image registration
	IJ.log(currentTime() + "s - Stitching all downsampled stacks into one sequence...");
	run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Up] grid_size_x="+stacknx+" grid_size_y="+stackny+" tile_overlap=10 first_file_index_i=1 directory=["+newdir0+"] file_names=s{ii}.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
	run("8-bit");
	run("Grays");
	
	//Removing slices beyond the number of slices in the stack from the sequence with the minimum slices
	for (j = 0; j < nSlices - reslice; j++) {
		setSlice(reslice+j+1);
		run("Delete Slice", "delete=slice");
	}

	//Flattening the sequence using Z-Projection based of standard deviation
	run("Z Project...", "projection=[Standard Deviation]");
	finalstackname0 = findir + "Fused and flattened.png";
	saveAs("png", finalstackname0);

	//Close the original sequence and the flattened sequence image
	close();
	close();
	
	//Delete temp files and directory
	IJ.log(currentTime() + "s - Deleting temporary files...");
	templist = getFileList(newdir0);
	for (i = 0; i < templist.length; i++) {
		File.delete(newdir0 + templist[i]);
	}
	File.delete(newdir0);
	
	//Stitch the binary sequence
	IJ.log(currentTime() + "s - Stitching all binary downsampled stacks into one sequence...");
	run("Grid/Collection stitching", "type=[Grid: row-by-row] order=[Right & Up] grid_size_x="+stacknx+" grid_size_y="+stackny+" tile_overlap=10 first_file_index_i=1 directory=["+newdir+"] file_names=s{ii}.tif output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");	
	//Convert to grayscale 8-bit (Red LUT opens after fusing)
	run("8-bit");
	run("Grays");
	
	//Removing slices beyond the number of slices in the stack from the sequence with the minimum slices
	for (j = 0; j < nSlices - reslice; j++) {
		setSlice(reslice+j+1);
		run("Delete Slice", "delete=slice");
	}
	
	//Save slice images of fused stack
	IJ.log(currentTime() + "s - Saving sequence...");
	finalpath = findir + "Fused/";
	File.makeDirectory(finalpath);
	for (i=0; i<nSlices; i++) {
		setSlice(i+1);
		finalname = finalpath + "s" + i+1 + ".png";
		saveAs("PNG", finalname);
	}
	//Save stitched, binary, sequence stack
	finalstackname = findir + "Fused.tif";
	saveAs("Tiff", finalstackname);
    IJ.log(currentTime() + "s - Completed.");
	waitForUser("Downscaling and fusing of sequence in '"+ workdirname +"' complete. Press 'OK' to close the open sequence or close the window to end now.");
	close();

	//Delete temp files and directory
	IJ.log(currentTime() + "s - Deleting temporary files...");
	for (i = 0; i < templist.length; i++) {
		File.delete(newdir + templist[i]);
	}
	File.delete(newdir0);
}

function makeRois(workdir) {
	//Get initial time
	start = getTime();

	//Get workspace directory name
	workdirname = File.getName(workdir);
	
	//Define the final outputs directory, fused sequence path and results table path
    findir = workdir + "/Final Outputs/";
    finalpath = findir + "Fused.tif";
	resultdir = findir + "Results.csv";
	
	//Open the stitched sequence
    open(finalpath);

	//Open results table
    run("Results... ", "open=["+resultdir+"]"); 

	//Read XYZ coordinates from the results table and add them to the ROI manager
	for (i = 0; i < nResults; i++) {
		x = getResult("x", i);
		y = getResult("y", i);
		z = getResult("z", i);
		setSlice(z);
		makePoint(x, y);
		roiManager("Add");
	}

    //Saving ROIs
    IJ.log(currentTime() + "s - Sequence: Saving ROIs...");
	roipath = findir + "ROIs.zip";
	roiManager("Save", roipath);

    //Give choice to close or keep stack
    IJ.log(currentTime() + "s - Completed.");
	waitForUser("Data generation of sequence in '"+ workdirname +"' complete. Press 'OK' to close the open sequence and clear ROIs or close the window to end now.");
	roiManager("Delete");
	close();
}

//Get workspace directory
workdir = 0;
//workdir = "copy paste the workspace directory printed in the log window to skip this."
if (workdir == 0){
	workdir = getDirectory("Select your workspace directory (You should have one workspace directory per sequence)"); 
}


//////Main Section//////
//WARNING: starting a script will close any open images without saving them
//-Before you begin, load the sequence in LAS-X, make sure only your raw stacks are within the sequence, delete any merged or processed stacks you find.
//-To figure out which channel to keep or delete, open a stack from your sequence in ImageJ and find out the total number of channels (t_c) and the channel number you are measuring (g_c).

//-1
//stack2Images(workdir);

//-2
//MATLAB: deNoise()

//-3
//images2Stack(workdir);

//-4
//imageRestore(workdir);

//-5
downFuse(workdir);

//-6 gridseg = total number of segments in heatmap (default = 100)
//MATLAB: objectSegmentation(gridseg)

//-7
//MATLAB: timeAnalysis(seqnum)

//-8 (optional)
//makeRois(workdir); 
