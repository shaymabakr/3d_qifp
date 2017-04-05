function  outputStructure = load_volume(input)
% LOAD_VOLUME this function receives a Dicom Segmentation file and an table
%   with the Dicom Images files, then it loads a region of interest
%   containing the segmented values. It returns a 3D matrix.
%
% Input:
%   configurationArray      
%
% Output:
%
%
% Created by:       Sebastian Echegaray 
% Created on:       2013-04-02


%% Initialization
% Copying input parameters to local variables to avoid reuse
DcmSegmentationObjectFileTable = input.DcmSegmentationObjectFileTable;
dsoUid = input.processingUid;
dicomSegmentationObjectFile = DcmSegmentationObjectFileTable(char(dsoUid));
dcmImageFileArray = input.DcmImageFileTable;
DcmImageFileSeriesNumberArray = input.DcmImageFileSeriesNumber;

DcmImageFileSeriesLocation = input.DcmImageFileSeriesLocation;
DcmImageFileSeriesLocationsAvailable = ...
 input.DcmImageFileSeriesLocationsAvailable;


configurationArray = struct();
configurationArray.LOAD_VOLUME_PADDING = input.padding;


%% Configuration and Validation

% Check that the padding is set
if ~isfield(configurationArray, 'LOAD_VOLUME_PADDING') 
    error('LOAD_VOLUME_PADDING was not defined. Dicom images cannot be load');
end

% Check if there the Padding is defined as one-dimension or 3-dimensional
if numel(configurationArray.LOAD_VOLUME_PADDING) == 1
    LOAD_VOLUME_PADDING = ...
        repmat(configurationArray.LOAD_VOLUME_PADDING, [3,1]);
elseif numel(configurationArray.LOAD_VOLUME_PADDING) == 3
    LOAD_VOLUME_PADDING = configurationArray.LOAD_VOLUME_PADDING;
else     
    error('LOAD_VOLUME_PADDING was expected to have 1 or 3 elements.');
end

%% Load Dicom Segmentation Value and Info
dicomSegmentationObjectMask = squeeze(dicomread(dicomSegmentationObjectFile));
dicomSegmentationObjectInfo = dicominfo(dicomSegmentationObjectFile);

% Instance ID of the second image in the original dicom series) 
% dicomImageSopInstanceUid = dicomSegmentationObjectInfo. ...
%     SharedFunctionalGroupsSequence.Item_1.DerivationImageSequence. ...
%     Item_1.SourceImageSequence.(['Item_' num2str(2)]). ...
%     ReferencedSOPInstanceUID;
dicomImageSopInstanceUid = dicomSegmentationObjectInfo. ...
    ReferencedSeriesSequence.Item_1.ReferencedInstanceSequence. ...
    (['Item_' num2str(2)]).ReferencedSOPInstanceUID;


% Metadata of the original image
dicomImageInfo = dicominfo(dcmImageFileArray(dicomImageSopInstanceUid));

% Get and extract image positions.
% numSlicesDSO = numel(fieldnames(dicomSegmentationObjectInfo. ...
%     SharedFunctionalGroupsSequence.Item_1.DerivationImageSequence. ...
%     Item_1.SourceImageSequence));
numSlicesDSO = numel(fieldnames(dicomSegmentationObjectInfo. ...
    ReferencedSeriesSequence.Item_1.ReferencedInstanceSequence));
zResolutions = zeros(numSlicesDSO,1);

for nSDSO = 1:numSlicesDSO
%     tmpSDSO  = dicomSegmentationObjectInfo. ...
%         SharedFunctionalGroupsSequence.Item_1. ...
%         DerivationImageSequence.Item_1.SourceImageSequence. ...
%         (['Item_' num2str(nSDSO)]).ReferencedSOPInstanceUID;
    tmpSDSO = dicomSegmentationObjectInfo. ...
        ReferencedSeriesSequence.Item_1.ReferencedInstanceSequence. ...
        (['Item_' num2str(nSDSO)]).ReferencedSOPInstanceUID;

    tmpDicomImageInfo2 = dicominfo(dcmImageFileArray(tmpSDSO));
    zResolutions(nSDSO) = tmpDicomImageInfo2.ImagePositionPatient(3);
    if ((nSDSO > 1) && (zResolutions(nSDSO) == zResolutions(nSDSO-1)))
        continue
    end
end
nonSortedzResolutions = zResolutions;
% Sort image positions
zResolutions = sort(zResolutions);

% Find X and Y pixel determined
yDicomSegmentationResolution = dicomImageInfo.PixelSpacing(1);
xDicomSegmentationResolution = dicomImageInfo.PixelSpacing(2);

% Z voxel spacing determined by the minimum distance between slices
zDicomSegmentationResolution = min(abs(diff(zResolutions)));

% Ugly hack to see if the DSO slices are continous
if any((diff(zResolutions) - min(diff(zResolutions))) > 0.0001)
    warning('DSO has non-contiguous slices');
end

% Available locations
locationsAvailable = ... 
    DcmImageFileSeriesLocationsAvailable(dicomImageInfo.SeriesInstanceUID);

% Find all locations that need to be loaded
minLocation = min(zResolutions);
maxLocation = max(zResolutions);
inbetweenLocationsMask = ...
    (locationsAvailable >= minLocation) & ...
    (locationsAvailable <= maxLocation);
inbetweenLocations = sort(locationsAvailable(inbetweenLocationsMask));
missingSlices = setdiff(inbetweenLocations, nonSortedzResolutions);

% For all missing slices in the DSO:
zResolutions = zResolutions(end:-1:1);
nMissingSlices = numel(missingSlices);
slicesAdded  = nMissingSlices;
for iMissingSlice = 1:nMissingSlices
    missingSlice = missingSlices(iMissingSlice);
    insertPlace = find(diff((zResolutions - missingSlice) > 0));
    zResolutions = [zResolutions(1:insertPlace); ...
        missingSlice; ...
        zResolutions((insertPlace+1):end)];
    dicomSegmentationObjectMask = cat(3, ...
        dicomSegmentationObjectMask(:,:,1:insertPlace), ...
        false(size(dicomSegmentationObjectMask(:,:,1))), ....
        dicomSegmentationObjectMask(:,:,(insertPlace+1):end) ...
        );
    
end


%% Lets calculate the padding from mm to voxels.
yVolumePaddingInVoxels = ceil(LOAD_VOLUME_PADDING(1) ./ ...
    yDicomSegmentationResolution);
xVolumePaddingInVoxels = ceil(LOAD_VOLUME_PADDING(2) ./ ...
    xDicomSegmentationResolution);
zVolumePaddingInVoxels = ceil(LOAD_VOLUME_PADDING(3) ./ ...
    zDicomSegmentationResolution);

%% Lets find the bounding box for the segmentation
dicomSegmentationObjectZIndexArray = ...
    find(squeeze(sum(sum(dicomSegmentationObjectMask, 1), 2)));
dicomSegmentationObjectXIndexArray = ...
    find(squeeze(sum(sum(dicomSegmentationObjectMask, 3), 1)));
dicomSegmentationObjectYIndexArray = ...
    find(squeeze(sum(sum(dicomSegmentationObjectMask, 3), 2)));

% Z-Index

% firstDicomUid = dicomSegmentationObjectInfo.SharedFunctionalGroupsSequence.Item_1.DerivationImageSequence.Item_1.SourceImageSequence.(['Item_' num2str(dicomSegmentationObjectZIndexArray(1))]).ReferencedSOPInstanceUID;
% lastDicomUid  = dicomSegmentationObjectInfo.SharedFunctionalGroupsSequence.Item_1.DerivationImageSequence.Item_1.SourceImageSequence.(['Item_' num2str(dicomSegmentationObjectZIndexArray(end) - slicesAdded)]).ReferencedSOPInstanceUID;

firstDicomUid = dicomSegmentationObjectInfo.ReferencedSeriesSequence.Item_1.ReferencedInstanceSequence.(['Item_' num2str(dicomSegmentationObjectZIndexArray(1))]).ReferencedSOPInstanceUID;
lastDicomUid  = dicomSegmentationObjectInfo.ReferencedSeriesSequence.Item_1.ReferencedInstanceSequence.(['Item_' num2str(dicomSegmentationObjectZIndexArray(end) - slicesAdded)]).ReferencedSOPInstanceUID;


firstDicomImageInfo = dicominfo(dcmImageFileArray(firstDicomUid));
seriesUid = dicomImageInfo.SeriesInstanceUID;
lastDicomImageInfo = dicominfo(dcmImageFileArray(lastDicomUid));

if firstDicomImageInfo.InstanceNumber < lastDicomImageInfo.InstanceNumber
    signFlag = +1;
else 
    signFlag = -1;
end

dicomSegmentationObjectZFirstIndex = firstDicomImageInfo.InstanceNumber - (signFlag *zVolumePaddingInVoxels);
dicomSegmentationObjectZLastIndex = lastDicomImageInfo.InstanceNumber + (signFlag * zVolumePaddingInVoxels);

dicomSegmentationObjectZFirstIndexOrig = dicomSegmentationObjectZIndexArray(1);
dicomSegmentationObjectZLastIndexOrig  = dicomSegmentationObjectZIndexArray(end);

% Rows 
dicomSegmentationObjectYFirstIndex = dicomSegmentationObjectYIndexArray(1) - ...
    yVolumePaddingInVoxels;
dicomSegmentationObjectYLastIndex  = dicomSegmentationObjectYIndexArray(end) + ...
    yVolumePaddingInVoxels;

% Columns
dicomSegmentationObjectXFirstIndex = dicomSegmentationObjectXIndexArray(1) - ...
    xVolumePaddingInVoxels;
dicomSegmentationObjectXLastIndex  = dicomSegmentationObjectXIndexArray(end) + ...
    xVolumePaddingInVoxels;

%% Lets Load the Dicom Images. 

% Lets initialize the result array
dicomImageArray = zeros( ...
    dicomSegmentationObjectYLastIndex - dicomSegmentationObjectYFirstIndex + 1, ...
    dicomSegmentationObjectXLastIndex - dicomSegmentationObjectXFirstIndex + 1, ...
    abs(dicomSegmentationObjectZLastIndex - dicomSegmentationObjectZFirstIndex) + 1 ...
    );
dicomImageInfoArray = cell(...
    abs(dicomSegmentationObjectZLastIndex - dicomSegmentationObjectZFirstIndex) + 1, ...
    1);

skippedSlicesIndex = [];
for dicomSegmentationObjectSliceNo = ...
        dicomSegmentationObjectZFirstIndex:signFlag:dicomSegmentationObjectZLastIndex
    
    % Load the slice referred by the Dicom Segmentation Object Info
    try
        % Convert the index in the loop to a 1..numel index
        dicomImageIndex = dicomSegmentationObjectSliceNo - ...
            min(dicomSegmentationObjectZFirstIndex, dicomSegmentationObjectZLastIndex) + 1;

        dicomImageFile = DcmImageFileSeriesNumberArray([seriesUid '-' num2str(dicomSegmentationObjectSliceNo)]);
        dicomImageSlice = dicomread(dicomImageFile);
        dicomImageInfo = dicominfo(dicomImageFile);   

        % Crop the Slice into a ROI
        dicomImageSliceCropped = dicomImageSlice(...
            dicomSegmentationObjectYFirstIndex:dicomSegmentationObjectYLastIndex, ...
            dicomSegmentationObjectXFirstIndex:dicomSegmentationObjectXLastIndex);

        % Store the cropped image and its info into the image stack 
        dicomImageArray(:,:,dicomImageIndex) = dicomImageSliceCropped;
        dicomImageInfoArray{dicomImageIndex} = dicomImageInfo;
    catch
        warning('Not enough space for full padding');
        skippedSlicesIndex = [skippedSlicesIndex, dicomImageIndex];
    end
end

% Remove Blank slices
if ~isempty(skippedSlicesIndex)
    dicomImageInfoArray(skippedSlicesIndex) = [];
    dicomImageArray(:,:,skippedSlicesIndex) = [];
end

%% Find the new segmentation mask to fit the cropped volume
dicomSegmentationObjectCropped = ...
    dicomSegmentationObjectMask(...
    dicomSegmentationObjectYFirstIndex:dicomSegmentationObjectYLastIndex, ...
    dicomSegmentationObjectXFirstIndex:dicomSegmentationObjectXLastIndex, ...
    dicomSegmentationObjectZFirstIndexOrig:dicomSegmentationObjectZLastIndexOrig  ...    
    );

padSliceMask = zeros(size(dicomSegmentationObjectCropped,1), size(dicomSegmentationObjectCropped,2), 'uint8');
padMask = repmat(padSliceMask, [1, 1, zVolumePaddingInVoxels]);
dicomSegmentationObjectCropped = cat(3, padMask, dicomSegmentationObjectCropped, padMask);

% Remove Blank slices
if ~isempty(skippedSlicesIndex)
    if signFlag == -1
        dicomSegmentationObjectCropped(:,:,end - skippedSlicesIndex + 1) = [];
    else
        dicomSegmentationObjectCropped(:,:,skippedSlicesIndex) = [];
    end
end

%% Create the result
outputStructure.intensityVOI = dicomImageArray;

% Scale by Intercept and Slope if it exists
if isfield(dicomImageInfoArray{1}, 'RescaleIntercept')
    outputStructure.intensityVOI = outputStructure.intensityVOI + ...
        dicomImageInfoArray{1}.RescaleIntercept;
end
if isfield(dicomImageInfoArray{1}, 'RescaleSlope')
    outputStructure.intensityVOI = outputStructure.intensityVOI / ...
        dicomImageInfoArray{1}.RescaleSlope;
end

outputStructure.infoVOI = dicomImageInfoArray;

try
    if signFlag > 0 
        outputStructure.segmentationVOI = dicomSegmentationObjectCropped;        
    else
        outputStructure.segmentationVOI = flip(dicomSegmentationObjectCropped, 3);
    end
catch
    outputStructure.segmentationVOI = dicomSegmentationObjectCropped;        
end
outputStructure.segmentationVOI = logical(outputStructure.segmentationVOI);
outputStructure.segmentationInfo = dicomSegmentationObjectInfo;
end