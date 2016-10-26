% You can change anything you want in this script.
% It is provided just for your convenience.
clear; clc; close all;
tic;
img_path = './train/';
class_num = 30;
img_per_class = 60;
img_num = class_num .* img_per_class;
feat_dim = size(train_feature_extraction(imread('./val/Balloon/329060.JPG')),2);

folder_dir = dir(img_path);
% feat_train = zeros(img_num,feat_dim);
% Will hold ALL feature descriptors for each image.
all_feat_train = cell(img_num,1);
label_train = cell(class_num,1);

num_kmean_centroids = 800;
max_k_it = 25;

labeled_rgb_hists = cell(class_num,1);
% For each set of labeled images...
for i = 1:length(folder_dir)-2
    
    img_dir = dir([img_path,folder_dir(i+2).name,'/*.JPG']);
    if isempty(img_dir)
        img_dir = dir([img_path,folder_dir(i+2).name,'/*.BMP']);
    end

    labeled_rgb_hists{i} = zeros(img_per_class,64,3);
    
    for j = 1:length(img_dir)        
        img = imread([img_path,folder_dir(i+2).name,'/',img_dir(j).name]);

        % The current image's feature descriptors are added.
        all_feat_train{(i-1)*img_per_class+j} = train_feature_extraction(img);
        
        % Compute RGB histogram with 4 bins per channel (for efficiency).
        
%         rgb_hist = zeros(3,256);
%         img = double(img);
%         for row=1:size(img,1)
%             for col=1:size(img,2)
%                 for chan=1:3
%                     rgb_hist(chan,img(row,col,chan)+1) = rgb_hist(chan,img(row,col,chan)+1) + 1;
%                 end
%             end
%         end
        
        % Now combine into 4 buckets.
%         binned_rgb(:,1) = sum(rgb_hist(:,1:64),2);
%         binned_rgb(:,2) = sum(rgb_hist(:,65:128),2);
%         binned_rgb(:,3) = sum(rgb_hist(:,129:192),2);
%         binned_rgb(:,4) = sum(rgb_hist(:,192:256),2);
        
        
%Split into RGB Channels
    Red = img(:,:,1);
    Green = img(:,:,2);
    Blue = img(:,:,3);
    %Get histValues for each channel
    [yRed, x] = imhist(Red,64);
    [yGreen, x] = imhist(Green,64);
    [yBlue, x] = imhist(Blue,64);
        
    % Normalize
    labeled_rgb_hists{i}(j,:,:) = [yRed(:), yGreen(:), yBlue(:)] ./ (size(img,1) * size(img,2));

    end
    
end

combined_features = [];
% Unpack cell array and concatenate vertically...
for ind=1:length(all_feat_train)
    combined_features = [combined_features; all_feat_train{ind}];
end

% Compute k means using all features of every image as data points.
% TODO right now 30 words will be formed. find more intelligent way to
% decide k value.
[k_words, train_imgs_bag_of_words] = train_kmeans(combined_features, num_kmean_centroids, max_k_it);
disp('k-means completed...\n');

toc
% Make train_imgs_bag_of_words into cell array broken up by which features
% belong to.. {label} -> [numImages x numWords]

bags_of_words = cell(class_num * img_per_class,1);
curr_im = 1;

% TODO figure this crap out... Need to end up with a histogram of words
% frequency for each image.
for i = 1:length(all_feat_train)
    curr_cell = all_feat_train{i};
    curr_bag = zeros(1,1);
    
    for j = 1:size(curr_cell,1)
        curr_bag(j) = train_imgs_bag_of_words(curr_im);
        curr_im = curr_im + 1;
    end
    
    bags_of_words{i} = curr_bag;
    
    
    
end

% Create histograms 1 x numWords for each image. (not yet normalized)


hist_of_words = cell(class_num * img_per_class,1);
for i = 1:length(bags_of_words)
    
    curr_hist = zeros(num_kmean_centroids,1);
    
    curr_bag = bags_of_words{i};
    for j = 1:length(bags_of_words{i})
        curr_hist(curr_bag(j)) = curr_hist(curr_bag(j)) + 1;
    end
    
    hist_of_words{i} = curr_hist;
end

labeled_hist_of_words = cell(class_num,1);
%TODO Now, split up cells by labels...
for i = 1:class_num
    for j=1:img_per_class
        indx = (i-1)*img_per_class+j;
        labeled_hist_of_words{i}(j,:) = hist_of_words{indx};
    end
end

% Only k_words and labeled_hist_of_words will matter.
% k_words being the 128 dimensional representation of chosen words.
% labeled_hist_of_words being cell per label, with each cell housing the
% bag of words histogram representation of each image of that label.
save('model.mat','k_words','labeled_hist_of_words','labeled_rgb_hists');
