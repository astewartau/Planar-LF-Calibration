%% 
% This file is an adaptation of MATLAB's 'Feature Based 
% Panoramic Image Stitching' demonstration.
% 
% Ashley Stewart
% Queensland University of Technology
% Australia
% 06/11/2016

%% 
% BuildTransformMatrixFromCalibrationImages(calibrationSetDir)
%   calibrationSetDir: 
%           The directory containing the calibration set
%
% Returns a series of geometric transformations that describe
% the relative transforms of images in a calibration set 
% captured by a camera array, according to Ashley Stewart's 
% panoramic calibration procedure for light field acquisition. 
%
% The transformation matrix returned can be used to rectify
% future image sets captured by the same camera array. 
%
% The transformation matrix will contain transforms in 
% alphabetical order according to the calibration set 
% filenames.

function tforms = BuildTransformMatrixFromCalibrationImages...
    (calibrationSetDir)

% Load calibration images
images = imageSet(calibrationSetDir);

% Initialise the first image and detect features
I = read(images, 1);
grayImage = rgb2gray(I);
points = detectSURFFeatures(grayImage);
[features, points] = extractFeatures(grayImage, points);

% Initialise transforms to the identity matrix
tforms(images.Count) = projective2d(eye(3));

% Iterate over remaining image pairs
for n = 2:images.Count

    % Store points and features for I(n-1)
    pointsPrevious = points;
    featuresPrevious = features;

    % Read I(n)
    I = read(images, n);

    % Detect and extract SURF features for I(n)
    grayImage = rgb2gray(I);    
    points = detectSURFFeatures(grayImage);    
    [features, points] = extractFeatures(grayImage, points);

    % Find correspondences between I(n) and I(n-1)
    indexPairs = matchFeatures(features, ...,
        featuresPrevious, 'Unique', true);
    matchedPoints = points(indexPairs(:,1), :);
    matchedPointsPrev = pointsPrevious(indexPairs(:,2), :);
    
    % Estimate the transformation between I(n) and I(n-1)
    tforms(n) = estimateGeometricTransform(matchedPoints,...
        matchedPointsPrev, 'projective',...
        'Confidence', 99.9, 'MaxNumTrials', 2000);

    % Compute T(1) * ... * T(n-1) * T(n)
    tforms(n).T = tforms(n-1).T * tforms(n).T; 
end

%%
% At this point, all the transformations in |tforms| are 
% relative to the first image. 
% 
% Using the first image as the initial reference does not 
% produce the best result because it tends to distort most of
% the images. An improved result can be achieved by modifying
% the transformations such that the center of the scene is the
% least distorted. This is accomplished by inverting the 
% transform for the center image and applying that transform to
% all the others.
%
% Start by using the |projective2d| |outputLimits| method to 
% find the output limits for each transform. The output limits
% are then used to automatically find the image that is roughly
% in the center of the scene.
imageSize = size(I);  % all the images are the same size

% Compute the output limits  for each transform
for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), ...
        [1 imageSize(2)], [1 imageSize(1)]);    
end

%%
% Next, compute the average X limits for each transforms and 
% find the image that is in the center. Only the X limits are
% used here because the scene is known to be horizontal. If 
% another set of images are used, both the X and Y limits may
% need to be used to find the center image.

avgXLim = mean(xlim, 2);
[~, idx] = sort(avgXLim);
centerIdx = floor((numel(tforms)+1)/2);
centerImageIdx = idx(centerIdx);

%%
% Finally, apply the center image's inverse transform to all 
% the others.
Tinv = invert(tforms(centerImageIdx));

for i = 1:numel(tforms)    
    tforms(i).T = Tinv.T * tforms(i).T;
end

end