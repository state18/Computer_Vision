% You can change anything you want in this script.
% It is provided just for your convenience.
clear; clc; close all;

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
% label_train = zeros(img_num,1);

% For each set of labeled images...
for i = 1:length(folder_dir)-2
    
    img_dir = dir([img_path,folder_dir(i+2).name,'/*.JPG']);
    if isempty(img_dir)
        img_dir = dir([img_path,folder_dir(i+2).name,'/*.BMP']);
    end
    
%     label_train((i-1)*img_per_class+1:i*img_per_class) = i;
    
    
    for j = 1:length(img_dir)        
        img = imread([img_path,folder_dir(i+2).name,'/',img_dir(j).name]);
%         all_feat_train((i-1)*img_per_class+j,:) = train_feature_extraction(img);

        % The current image's feature descriptors are added.
        all_feat_train{(i-1)*img_per_class+j} = train_feature_extraction(img);
        
    end
    
    % TODO Use inverse indexing here to update the database of words to
    % images, using all_feat_train.
    
    
    
    % TODO Try using different k values with k-means alg to get the words.
    % Try different combinations of images grouped together
    %   * All images of same label?
    %   * Random combinations? Then optimize using bayes opt?
    
    % TODO Change word generation per set of labeled images to using ALL of
    % them and then doing k means.
    
    % TODO send in 2D matrix of features, not img x features x 128
    img_indx = (i-1)*img_per_class+1:(i-1)*img_per_class+length(img_dir);
    combined_features = [];
    for ind=img_indx
        combined_features = [combined_features; all_feat_train{ind}];
    end
    k_words = train_kmeans(combined_features,length(img_indx));
    
    % Now that words for current image label have been established, 
    % TODO make some structure that maps word # to labels... Later on, when
    % looking at validation set, and getting words from image, they will be
    % the words in this structure that resemble the features in validation
    % image the closest.
    label_train{i} = k_words;
    fprintf('Label %d complete...\n',i);
end

% TODO tf-idf weighting to reexamine the features of the images. This will
% allow me to get an idea of which words are more important to describe an
% image. This may actually be done during testing and not training.


% Right now, label_train is really the only needed one.
save('model.mat','all_feat_train','label_train');
