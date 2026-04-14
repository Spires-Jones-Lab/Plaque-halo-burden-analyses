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
function measureCombo(chA, chB, chC, idx, z, ROI_results) {

    sumPerc = 0;

    for (s = 1; s <= z; s++) {

        selectWindow(chA); setSlice(s); run("Duplicate...", "title=tA");
        selectWindow(chB); setSlice(s); run("Duplicate...", "title=tB");

        imageCalculator("Multiply create", "tA", "tB");
        rename("comboAB");

        if (chC != "") {
            selectWindow(chC); setSlice(s); run("Duplicate...", "title=tC");
            imageCalculator("Multiply create", "comboAB", "tC");
            rename("combo");
            close("comboAB");
            close("tC");
        } else rename("combo");

        selectWindow("combo");
        roiManager("Select", 0);
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);

        close("combo");
        close("tA");
        close("tB");
    }

    ROI_results[idx] = sumPerc / z;
}

// Measure combination OUTSIDE ROI (PLAQUES)
function measureComboOutside(chA, chB, chC, idx, z, OUT_results) {

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
        rename("comboAB");

        if (chC != "") {
            selectWindow(chC); setSlice(s); run("Duplicate...", "title=tC");
            imageCalculator("Multiply create", "comboAB", "tC");
            rename("combo");
            close("comboAB");
            close("tC");
        } else rename("combo");

        selectWindow("combo");
        run("Restore Selection");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);

        close("combo");
        close("tA");
        close("tB");
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
        run("Select None");
        run("Select All");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);
    }

    OUT_results[idx] = sumPerc / z;
}

function measureFullImageCombo(chA, chB, chC, idx, z, OUT_results) {

    sumPerc = 0;

    for (s = 1; s <= z; s++) {

        selectWindow(chA); setSlice(s); run("Duplicate...", "title=tA");
        selectWindow(chB); setSlice(s); run("Duplicate...", "title=tB");

        imageCalculator("Multiply create", "tA", "tB");
        rename("comboAB");

        if (chC != "") {
            selectWindow(chC); setSlice(s); run("Duplicate...", "title=tC");
            imageCalculator("Multiply create", "comboAB", "tC");
            rename("combo");
            close("comboAB");
            close("tC");
        } else rename("combo");

        selectWindow("combo");
        run("Select None");
        run("Select All");
        run("Measure");
        n = nResults - 1;
        sumPerc += getResult("%Area", n);

        close("combo");
        close("tA");
        close("tB");
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

    close("roiMaskQC");
    close("outsideMaskQC");
    close("QC_outside_overlay");
}

// ============================================================
// MAIN MACRO
// ============================================================

inputDir = getDirectory("Choose input folder");
outputPath = inputDir + "halo_results.csv";
qcDir = inputDir + "QC/";
File.makeDirectory(qcDir);

plaque_channel = 2;
halo_dilate_pixels = 35;

// Label order
labels = newArray("C3","C4","C5","C3C4","C3C5","C3C4C5","C4C5");

// ============================================================
// MARKER MAPPING SYSTEM
// ============================================================

markerMap = newArray(7);
markerMap[0] = "SYO";
markerMap[1] = "GFAP";
markerMap[2] = "AT8";
markerMap[3] = "SYOGFAP";
markerMap[4] = "SYOAT8";
markerMap[5] = "SYOGFAPAT8";
markerMap[6] = "GFAPAT8";

// ============================================================
// CSV HEADER
// ============================================================

file = File.open(outputPath);

header = "Image";

for (i = 0; i < labels.length; i++) {
    marker = markerMap[i];
    header += "," + marker + "_burden_plaquehalo";
    header += "," + marker + "_burden_fullstack";
}

print(file, header);

// ============================================================
// PROCESS IMAGES
// ============================================================

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

        ch3 = "C3-" + origTitle;
        ch4 = "C4-" + origTitle;
        ch5 = "C5-" + origTitle;

        selectWindow(ch3);
        getDimensions(w, h, c, z, t);

        ROI_results = newArray(7);
        OUT_results = newArray(7);

        // ============================================================
        // PLAQUE IMAGES
        // ============================================================
        if (isPlaque) {

            plaqueTitle = "C" + plaque_channel + "-" + origTitle;
            selectWindow(plaqueTitle);
            rename("PlaqueMask");

            run("Z Project...", "projection=[Max Intensity]");
            rename("PlaqueMax");

            run("Duplicate...", "title=PlaqueDilated");

            run("Invert");
            for (d = 0; d < halo_dilate_pixels; d++) run("Dilate");
            run("Invert");

            run("Convert to Mask");

            run("Analyze Particles...", "size=0-Infinity show=Masks clear");
            rename("LargestPlaque");

            run("Create Selection");

            roiManager("Reset");
            roiManager("Add");
            roiManager("Select", 0);

            saveAs("Tiff", qcDir + "haloMask-" + origTitle);
            roiManager("Save", qcDir + "ROI-" + origTitle + ".zip");

            saveOutsideQC(origTitle, ch3, qcDir);

            // ROI measurements
            measureSingleChannel(ch3, 0, z, ROI_results);
            measureSingleChannel(ch4, 1, z, ROI_results);
            measureSingleChannel(ch5, 2, z, ROI_results);

            measureCombo(ch3, ch4, "",   3, z, ROI_results);
            measureCombo(ch3, ch5, "",   4, z, ROI_results);
            measureCombo(ch3, ch4, ch5,  5, z, ROI_results);
            measureCombo(ch4, ch5, "",   6, z, ROI_results);

            // Outside measurements
            measureOutsideROI(ch3, 0, z, OUT_results);
            measureOutsideROI(ch4, 1, z, OUT_results);
            measureOutsideROI(ch5, 2, z, OUT_results);

            measureComboOutside(ch3, ch4, "",   3, z, OUT_results);
            measureComboOutside(ch3, ch5, "",   4, z, OUT_results);
            measureComboOutside(ch3, ch4, ch5,  5, z, OUT_results);
            measureComboOutside(ch4, ch5, "",   6, z, OUT_results);
        }

        // ============================================================
        // CONTROL IMAGES — FULL‑IMAGE BURDEN ONLY
        // ============================================================
        if (isControl) {

            for (idx = 0; idx < 7; idx++) ROI_results[idx] = 0;

            measureFullImageSingle(ch3, 0, z, OUT_results);
            measureFullImageSingle(ch4, 1, z, OUT_results);
            measureFullImageSingle(ch5, 2, z, OUT_results);

            measureFullImageCombo(ch3, ch4, "",   3, z, OUT_results);
            measureFullImageCombo(ch3, ch5, "",   4, z, OUT_results);
            measureFullImageCombo(ch3, ch4, ch5,  5, z, OUT_results);
            measureFullImageCombo(ch4, ch5, "",   6, z, OUT_results);
        }

        // ============================================================
        // WRITE CSV
        // ============================================================
        line = origTitle;

        for (idx = 0; idx < 7; idx++) {
            line += "," + ROI_results[idx];
            line += "," + OUT_results[idx];
        }

        print(file, line);

        close("*");
    }
}

setBatchMode(false);
print("Done. Results saved to: " + outputPath);
