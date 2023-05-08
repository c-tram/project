% Load and prepare your image dataset
pathToImages = imageDatastore('./', 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
[trainingSet, validationSet] = splitEachLabel(pathToImages, 0.8, 'randomized');

targetSize = [100 100];

% Extract features from our image dataset
features = {'Area', 'Perimeter', 'Eccentricity', 'ConvexArea', 'Solidity', 'EulerNumber'};
trainingFeatures = zeros(length(trainingSet.Files), length(features));
for i = 1:length(trainingSet.Files)
    img = imread(trainingSet.Files{i});
    img = imresize(img, targetSize);
    img = histeq(img); % apply histogram equalization to enhance contrast
    I = rgb2gray(img);
    I2 = imadjust(I);
    I3 = imfilter(I2, fspecial('sobel'));
    I4 = imopen(I3, strel('disk', 2));
    mask = imbinarize(I4, graythresh(I4));
    mask = imfill(mask, 'holes');
    mask = imerode(mask, strel('disk', 2));
    mask = imdilate(mask, strel('disk', 2));
    stats = regionprops('table',mask, features);
    trainingFeatures(i,:) = mean(stats{:,:}, 'omitnan');
end
trainingLabels = trainingSet.Labels;

% Train our classifier
ourClassifier = fitcecoc(trainingFeatures, trainingLabels);

% Evaluate our classifier
validationFeatures = zeros(length(validationSet.Files), length(features));
for i = 1:length(validationSet.Files)
    img = imresize(img, targetSize);
    img = histeq(img); % apply histogram equalization to enhance contrast
    I = rgb2gray(img);
    I2 = imadjust(I);
    I3 = imfilter(I2, fspecial('sobel'));
    I4 = imopen(I3, strel('disk', 2));
    mask = imbinarize(I4, graythresh(I4));
    mask = imfill(mask, 'holes');
    mask = imerode(mask, strel('disk', 2));
    mask = imdilate(mask, strel('disk', 2));
    stats = regionprops('table',mask, features);
    validationFeatures(i,:) = mean(stats{:,:}, 'omitnan');
end
validationLabels = validationSet.Labels;
predictedLabels = predict(ourClassifier, validationFeatures);
accuracy = mean(predictedLabels == validationLabels);

% Save classifier
save('Classifier.mat', 'ourClassifier');
