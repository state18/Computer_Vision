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

    labeled_rgb_hists{i} = zeros(img_per_class,32,3);
    
    for j = 1:length(img_dir)        
        img = imread([img_path,folder_dir(i+2).name,'/',img_dir(j).name]);

        % The current image's feature descriptors are added.
        all_feat_train{(i-1)*img_per_class+j} = train_feature_extraction(img);
        
                
        Red = imhist(img(:,:,1),32);
        Green = imhist(img(:,:,2),32);
        Blue = imhist(img(:,:,3),32);

        % Normalize
        labeled_rgb_hists{i}(j,:,:) = [Red(:), Green(:), Blue(:)] ./ (size(img,1) * size(img,2));

    end
    
end

combined_features = [];
% Unpack cell array and concatenate vertically...
for ind=1:length(all_feat_train)
    combined_features = [combined_features; all_feat_train{ind}];
end

% Compute k means using all features of every image as data points.
[k_words, train_imgs_bag_of_words] = train_kmeans(combined_features, num_kmean_centroids, max_k_it);

bags_of_words = cell(class_num * img_per_class,1);
curr_im = 1;

for i = 1:length(all_feat_train)
    curr_cell = all_feat_train{i};
    curr_bag = zeros(1,1);
    
    for j = 1:size(curr_cell,1)
        curr_bag(j) = train_imgs_bag_of_words(curr_im);
        curr_im = curr_im + 1;
    end
    
    bags_of_words{i} = curr_bag;
    
    
    
end

% Organize data.
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
for i = 1:class_num
    for j=1:img_per_class
        indx = (i-1)*img_per_class+j;
        labeled_hist_of_words{i}(j,:) = hist_of_words{indx};
    end
end

save('model.mat','k_words','labeled_hist_of_words','labeled_rgb_hists');
