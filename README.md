# Plaque-halo-burden-analyses
Macros for analyzing burden and colocalization of stained brain sections from people with Alzheimer's disease treated with the AN1792 vaccine

Aim: Analyse AN1792 immunized case confocal stacks
NOTE - image resolution 0.141 microns/pixel z step 0.3
experiment: 
•	4um paraffin sections from Alzheimer’s disease (AD), immunized AD, and control cases
•	Stained for methoxy (blue), pTau217 (-594), Homer1 (-488), CD68 (-647) in first experiment, methoxy (blue), synaptophysin (488), GFAP (594), AT8 (647)
•	Imaged on the confocal
•	10 image pairs per case (plaque and non-plaque from same cortical layer/site where possible)
Separate individual images in the series, save as individual channels in separate folders
•	Images from the confocal will be in .lif format. 
•	Copy raw image files into analysis folder 1.RawImages
•	There will be multiple images within each raw image file that is saved directly from the confocal. 
•	To analyse these images we need to separate each individual image within the series saved from the confocal 
•	To do this we use the macro: 
•	Bulk rename all of the images to remove parent filename e.g. 102-3-3-methoxy-homer488-pTau217594-CD68647.lif - and to change C=1 etc to correct suffix for channel
•	Doing this by batches as images are taken
Optional: Median filter the images to account for variability in intensity across each stack
•	Using macro: with radius = 1, subtract background rolling=10 on each stack 
•	In this study, filtering and background subtraction not helping SYO channel, methoxy WAS filtered as above
BLIND image files before segmentation using Fiji macro 
•	The first time you use it, you have to put this .jar file into the plugins folder for Fiji (in mac, finder - applications - Fiji, right click to show package contents, put this file in the folder (re-start Fiji required the first time you do this)
•	In ImageJ, find ‘Blind Experiment’ in the Plugins menu at the top. 
•	Click ‘Mask Filenames’ and point it to the folders with your separated images in them.
•	The names will be blinded automatically.  A file will be created in the folder called ‘blind_experiment.props’.  You can then segment your images and unblind them afterwards.
•	To unblind AFTER segmenting, put all your segmented images AND the ‘blind_experiment.props’ file into separate folders and click ‘Unmask Filenames’ in ImageJ.  You then point it to the .props file and it will automatically unblind everything for you.
Segment channels:
•	Using Array Tomography Analysis Tool downloaded from GitHub
When first using MATLAb, you need to find the AT analysis tool before it can be run.
Use the button at the top left and navigate to the folder where you have saved the AT analysis tool:
On the left sidebar, right-click on AAT.m and press 'run':
click segmentation on the pop-up menu:
Auto-local threshold: tends to be better for smaller objects (e.g. synapses). This might break larger objects into smaller pieces.
Fixed value threshold: tends to be better for big objects (e.g. plaques).
Option A: auto-local threshold
If you choose the auto-local threshold, the following window will open 
Window Size: defines the segmentation window. Making this smaller will break larger objects into smaller fragments, while making it bigger will merge objects together. Generally, you want this to be slightly higher than your object of interest.
C (Correction) Factor: increasing this will allow for dimmer greyscale values to be picked up. The higher the C-factor, the more permissive you are in your segmentation.
Mean/Median: usually mean works fine, there is not much difference between mean/median in this case.
Filt Object size: you can define the minimum/maximum objects you want to allow in your segmentation. If you have very large tears or artefacts, filtering by size can help to remove these. Note that the minimum object cannot go lower than 3.
Press previsualise to create an example of your segmented image, alongside a brightened version of the original:
Once you are comfortable that your segmented image accurately reflects the objects in the original greyscale image, press analyse.
•	Segmented images will be saved in a “segmented” folder alongside a parameters file. I rename these for each channel e.g. SegmentedGFAP
•	It’s a good idea to keep a record of the parameters you use for segmentation to allow re-use in future experiments: 
•	UNBLIND images before next step
Subtract noise from homer channel (to remove cell bodies and blood vessels which sometimes have staining)
•	Subtract homer artefact from homer segmented channels with this macro: 
•	
Merge segmented images into one image containing all channels you want to do coloc analysis on
•	Segmented images are saved within separate channel folders (i.e. all GFAP images in a single folder).
•	Rename images with bulk rename in finder (or windows equivalent) so they are compatible with the next macro: remove parent .lif filenames from the beginning of the filenames, remove C=x from end of filenames and replace with channel name so files end with -GFAP.tif or -SYO.tif etc
•	Create new folder called “merged” for merged images
•	Use macro to merge merge channels into one multichannel image. For different channel combinations will have to edit the macro accordingly to get the channels in the order you prefer. Version used here puts in all segmented channels: 
New macros here on Github to replace multiplication and burden steps 
•	Put all merged images from above in same folder
•	in macro, check all channels and set halo size (35 pixels for 5 micron halo, 71 pixels for 10 micron halo).
•	run macro selecting merged images folder
•	This new macro was validated against multiply and burden steps used previously and by manual analysis
Analyse burden outputs in R script

