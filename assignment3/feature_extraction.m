function feat = feature_extraction(img)
% Output should be a fixed length vector [1*dimension] for a single image. 
% Please do NOT change the interface.

% First, find interest points using Matlab's builtin SURF feature
% detector.
colored_img = img;

img = rgb2gray(img);
interestPoints = detectSURFFeatures(img);

% Compute descriptors for each feature. (128 dimensional space)
[features, corners] = extractFeatures(img,interestPoints,'SURFSize',128);

features = double(features);

% Now the feature descriptors are used to make a bag of words
% representation of the image.

% load in words' 128 dimensional features from training.
% Variable is called k_words
load model.mat;

% Assign each feature from the image to a word.
% 'feat' is the histogram representation of the bag of words.
feat = zeros(1,size(k_words,1));

for i=1:size(features,1)
    min_dist = Inf;
    for j=1:size(k_words,1)
        curr_dist = sum(abs(features(i,:) - k_words(j,:)));
        if curr_dist < min_dist
            closest_word = j;
            min_dist = curr_dist;           
        end
    end
    % Accumulate histogram.
    feat(closest_word) = feat(closest_word) + 1;
end


Red = imhist(colored_img(:,:,1),32);
Green = imhist(colored_img(:,:,2),32);
Blue = imhist(colored_img(:,:,3),32);


% Normalize
rgb_hist = [Red(:), Green(:), Blue(:)] ./ (size(colored_img,1) * size(colored_img,2));

if exist('rgb_hists.mat', 'file')
    
    load rgb_hists.mat;
    % Make sure the file is not leftover from prior trial run.
    % After every run, in the 'your_KNN' function, this file is deleted.
    rgb_hists(end+1,:,:) = rgb_hist;
else
    
    rgb_hists(1,:,:) = rgb_hist;
end

save ('rgb_hists.mat', 'rgb_hists');

end