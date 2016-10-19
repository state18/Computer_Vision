function [ features ] = train_feature_extraction( img )
%TRAIN_FEATURE_EXTRACTION get ALL feature descriptors of an image
%   Return num_feature_descriptors by 128 matrix.

% First, find interest points using Matlab's builtin SURF feature
% detector.
img = rgb2gray(img);
interestPoints = detectSURFFeatures(img);

% Compute descriptors for each feature. (128 dimensional space)
[features, corners] = extractFeatures(img,interestPoints,'SURFSize',128);

features = double(features);

end

