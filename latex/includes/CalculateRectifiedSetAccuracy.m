%% 
% This file is an adaptation of MATLAB's 'Feature Based 
% Panoramic Image Stitching' demonstration.
% 
% Ashley Stewart
% Queensland University of Technology
% Australia
% 06/11/2016

%% 
% CalculateRectifiedSetError(rectifiedSetDir)
%   rectifiedSetDir: 
%           The directory containing the rectified set
%
% Returns the average pixel error calculated in the
% x and y directions for a rectified image set.
function [avgPixelError, pixelError] = ...
    CalculateRectifiedSetAccuracy(rectifiedSetDir)

% Load rectified images
images = imageSet(rectifiedSetDir);

% Initialise the first image and detect features
I = read(images, 1);
grayImage = rgb2gray(I);

points = detectSURFFeatures(grayImage);
[features, points] = extractFeatures(grayImage, points);

% Pixel error
pixelError = {};

% The pixel error beyond which we remove as an outlier
outlierError = 50;

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
    
    % Calculate pixel error
    thisError = abs(matchedPoints.Location - ...
        matchedPointsPrev.Location);
    
    % Remove outliers
    thisError(thisError(:,1) > outlierError,:) = [];
    thisError(thisError(:,2) > outlierError,:) = [];
    
    pixelError{n-1} = thisError;
end

% Find the average pixel error in x and y directions
avgPixelError = mean(vertcat(pixelError{:}));

end