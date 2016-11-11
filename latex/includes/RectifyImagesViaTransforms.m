%% 
% Ashley Stewart
% Queensland University of Technology
% Australia
% 06/11/2016

%% 
% RectifyImagesViaTransforms(tforms, originalsDir, rectifiedDir)
%   tforms: 
%       A transformation set built by 
%       BuildTransformMatrixFromCalibrationImages
%   originalsDir:
%       The directory of the original images
%   rectifiedDir:
%       The directory to save rectified images to
%
% Rectifies an image set according to a series of
% transformations determined by analysing a calibration set
% via BuiltTransformMatrixFromCalibrationImages.
%
% Rectified image sets can be loaded via LFReadGantryArray.

function RectifyImagesViaTransforms(tforms, originalsDir, ...
    rectifiedDir)

% Changable parameters
scaleFactor = 0.33;
outputFormat = 'jpg';

% Load images
imageDir = fullfile(originalsDir);
images = imageSet(imageDir);

% Find the minimum and maximum output limits
imageSize = size(read(images, 1));
for i = 1:numel(tforms)
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), ...
        [1 imageSize(2)], [1 imageSize(1)]);
end

xMin = min([1; xlim(:)]);
xMax = max([imageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([imageSize(1); ylim(:)]);

% Final dimensions of each image
width  = round(xMax - xMin);
height = round(yMax - yMin);
imageDimensions = [height width];

% Construct an empty reference plane view
referencePlaneView = imref2d(imageDimensions, [xMin xMax], ...
        [yMin yMax]);

% Calculate how many digits there are in the number of images
digits = numel(num2str(images.Count));

for imageNum = 1:images.Count
    I = read(images, imageNum);

    
    warpedImage = imresize(imwarp(I, tforms(imageNum),...
        'OutputView', referencePlaneView), scaleFactor);

    imwrite(warpedImage,strcat(rectifiedDir, '/',...
        sprintf(strcat('%0', num2str(digits), 'd'),...
        imageNum), '.', outputFormat));
end

end