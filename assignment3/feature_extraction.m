function feat = feature_extraction(img)
% Output should be a fixed length vector [1*dimension] for a single image. 
% Please do NOT change the interface.

% First, find interest points using Matlab's builtin SURF feature
% detector.
img = rgb2gray(img);
interestPoints = detectSURFFeatures(img);

% Compute descriptors for each feature. (128 dimensional space)
[features, corners] = extractFeatures(img,interestPoints,'SURFSize',128);

features = double(features);

% Now the feature descriptors are used to make a bag of words
% representation of the image.

% load in words' 128 dimensional features from training.
load model.mat;

% Assign each feature from the image to a word. Words' indices are
% represented by their position in the label_train
for i=1:size(features,1)
    min_dist = Inf;
    for j=1:length(label_train)
        for k=1:size(label_train{j})
            curr_dist = sum(abs(features(i,:) - label_train{j}(k,:)));
            if curr_dist < min_dist
                % TODO not right, just testing
                feat(i) = j;
                min_dist = curr_dist;
            end
        end
    end
end


feat = datasample(feat,50);
% feat = rand([1,100]); % dummy, replace this with your algorithm

end