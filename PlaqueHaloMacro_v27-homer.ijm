// ============================================================
// FUNCTIONS — %AREA ONLY
// ============================================================

// Measure single channel within ROI (PLAQUES)
function measureSingleChannel(chTitle, idx, z, ROI_results) {
    sumPerc = 0;
    selectWindow(chTitle);
    roiManager("Select", 0);
    for (s = 1; s <= z; s++) {
        setSlice(s);
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
    }
    ROI_results[idx] = sumPerc / z;
}

// Measure single channel OUTSIDE ROI (PLAQUES)
function measureOutsideROI(chTitle, idx, z, OUT_results) {
    sumPerc = 0;
    selectWindow(chTitle);
    roiManager("Select", 0);
    run("Create Mask"); rename("roiMask");
    run("Invert");      rename("outsideMask");
    selectWindow("outsideMask");
    run("Create Selection");
    for (s = 1; s <= z; s++) {
        selectWindow(chTitle);
        setSlice(s);
        run("Restore Selection");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
    }
    close("roiMask");
    close("outsideMask");
    OUT_results[idx] = sumPerc / z;
}

// Measure combination within ROI (PLAQUES)
function measureCombo(chA, chB, idx, z, ROI_results) {
    sumPerc = 0;
    for (s = 1; s <= z; s++) {
        selectWindow(chA); setSlice(s); run("Duplicate...", "title=tA");
        selectWindow(chB); setSlice(s); run("Duplicate...", "title=tB");
        imageCalculator("Multiply create", "tA", "tB");
        rename("combo");
        selectWindow("combo");
        roiManager("Select", 0);
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
        close("combo"); close("tA"); close("tB");
    }
    ROI_results[idx] = sumPerc / z;
}

// Measure combination OUTSIDE ROI (PLAQUES)
function measureComboOutside(chA, chB, idx, z, OUT_results) {
    sumPerc = 0;
    roiManager("Select", 0);
    run("Create Mask"); rename("roiMask");
    run("Invert");      rename("outsideMask");
    selectWindow("outsideMask");
    run("Create Selection");
    for (s = 1; s <= z; s++) {
        selectWindow(chA); setSlice(s); run("Duplicate...", "title=tA");
        selectWindow(chB); setSlice(s); run("Duplicate...", "title=tB");
        imageCalculator("Multiply create", "tA", "tB");
        rename("combo");
        selectWindow("combo");
        run("Restore Selection");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
        close("combo"); close("tA"); close("tB");
    }
    close("roiMask");
    close("outsideMask");
    OUT_results[idx] = sumPerc / z;
}

// ============================================================
// FULL‑IMAGE MEASUREMENT (CONTROLS)
// ============================================================

function measureFullImageSingle(chTitle, idx, z, OUT_results) {
    sumPerc = 0;
    selectWindow(chTitle);
    for (s = 1; s <= z; s++) {
        setSlice(s);
        run("Select None"); run("Select All");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
    }
    OUT_results[idx] = sumPerc / z;
}

function measureFullImageCombo(chA, chB, idx, z, OUT_results) {
    sumPerc = 0;
    for (s = 1; s <= z; s++) {
        selectWindow(chA); setSlice(s); run("Duplicate...", "title=tA");
        selectWindow(chB); setSlice(s); run("Duplicate...", "title=tB");
        imageCalculator("Multiply create", "tA", "tB");
        rename("combo");
        selectWindow("combo");
        run("Select None"); run("Select All");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
        close("combo"); close("tA"); close("tB");
    }
    OUT_results[idx] = sumPerc / z;
}

// ============================================================
// QC FOR PLAQUES
// ============================================================

function saveOutsideQC(baseTitle, chTitle, qcDir) {
    roiManager("Select", 0);
    run("Create Mask"); rename("roiMaskQC");
    run("Invert");      rename("outsideMaskQC");
    saveAs("Tiff", qcDir + baseTitle + "_outsideMask.tif");
    selectWindow(chTitle);
    run("Duplicate...", "title=QC_outside_overlay");
    run("Restore Selection");
    run("Properties...", "stroke=red width=2");
    saveAs("Tiff", qcDir + baseTitle + "_outsideOverlay.tif");
    close("roiMaskQC"); close("outsideMaskQC"); close("QC_outside_overlay");
}

// ============================================================
// MAIN MACRO
// ============================================================

inputDir = getDirectory("Choose input folder");
outputPath = inputDir + "halo_results.csv";
qcDir = inputDir + "QC/";
File.makeDirectory(qcDir);

halo_dilate_pixels = 35;

// Label order for 3‑channel biology
labels = newArray("C2","C3","C2C3");

// Marker mapping
markerMap = newArray(3);
markerMap[0] = "Homer";
markerMap[1] = "pTau";
markerMap[2] = "HomerpTau";

// CSV header
file = File.open(outputPath);
header = "Image";
for (i = 0; i < labels.length; i++) {
    marker = markerMap[i];
    header += "," + marker + "_burden_plaquehalo";
    header += "," + marker + "_burden_fullstack";
}
print(file, header);

// Process images
list = getFileList(inputDir);
setBatchMode(true);

for (i = 0; i < list.length; i++) {

    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {

        open(inputDir + list[i]);
        origTitle = getTitle();
        run("Clear Results");

        isControl = endsWith(origTitle, "-C.tif") || endsWith(origTitle, "-C1.tif") || endsWith(origTitle, "-C2.tif");
        isPlaque  = endsWith(origTitle, "-P.tif") || endsWith(origTitle, "-P1.tif") || endsWith(origTitle, "-P2.tif");

        run("Split Channels");

        ch1 = "C1-" + origTitle;   // plaques
        ch2 = "C2-" + origTitle;   // Homer
        ch3 = "C3-" + origTitle;   // pTau

        selectWindow(ch2);
        getDimensions(w, h, c, z, t);

        ROI_results = newArray(3);
        OUT_results = newArray(3);

        // ============================================================
        // PLAQUE IMAGES
        // ============================================================
        if (isPlaque) {

            // --- Max projection ---
            selectWindow(ch1);
            run("Z Project...", "projection=[Max Intensity]");
            rename("PlaqueMax");

            // --- Convert to mask ---
            run("Convert to Mask");

            // --- Extract ALL plaques as ROIs ---
            roiManager("Reset");
            run("Analyze Particles...", "size=0-Infinity add");

            roiCount = roiManager("Count");

            if (roiCount == 0) {
                // No plaques → zero outputs
                for (idx = 0; idx < 3; idx++) {
                    ROI_results[idx] = 0;
                    OUT_results[idx] = 0;
                }
            } else {

                // --- Find largest ROI ---
                maxArea = 0;
                maxIndex = 0;

                for (r = 0; r < roiCount; r++) {
                    roiManager("Select", r);
                    run("Measure");
                    area = getResult("Area", nResults - 1);
                    if (area > maxArea) {
                        maxArea = area;
                        maxIndex = r;
                    }
                }

                // --- Select only the largest ROI ---
                roiManager("Select", maxIndex);

                // --- Convert largest ROI to mask ---
                run("Create Mask");
                rename("LargestPlaqueMask");

                // --- Dilate ONLY this mask ---
                selectWindow("LargestPlaqueMask");
                for (d = 0; d < halo_dilate_pixels; d++) run("Dilate");

                // --- Convert dilated mask back to ROI ---
                run("Create Selection");

                // --- Store ROI ---
                roiManager("Reset");
                roiManager("Add");
                roiManager("Select", 0);

                // --- Save QC ---
                saveAs("Tiff", qcDir + "haloMask-" + origTitle);
                roiManager("Save", qcDir + "ROI-" + origTitle + ".zip");

                // --- Measurements ---
                measureSingleChannel(ch2, 0, z, ROI_results);
                measureSingleChannel(ch3, 1, z, ROI_results);
                measureCombo(ch2, ch3, 2, z, ROI_results);

                measureOutsideROI(ch2, 0, z, OUT_results);
                measureOutsideROI(ch3, 1, z, OUT_results);
                measureComboOutside(ch2, ch3, 2, z, OUT_results);
            }

            // Cleanup
            if (isOpen("PlaqueMax")) close("PlaqueMax");
            if (isOpen("LargestPlaqueMask")) close("LargestPlaqueMask");
        }

        // ============================================================
        // CONTROL IMAGES — FULL‑IMAGE BURDEN ONLY
        // ============================================================
        if (isControl) {
            for (idx = 0; idx < 3; idx++) ROI_results[idx] = 0;
            measureFullImageSingle(ch2, 0, z, OUT_results);
            measureFullImageSingle(ch3, 1, z, OUT_results);
            measureFullImageCombo(ch2, ch3, 2, z, OUT_results);
        }

        // ============================================================
        // WRITE CSV
        // ============================================================
        line = origTitle;
        for (idx = 0; idx < 3; idx++) {
            line += "," + ROI_results[idx];
            line += "," + OUT_results[idx];
        }
        print(file, line);

        close("*");
    }
}

setBatchMode(false);
print("Done. Results saved to: " + outputPath);
