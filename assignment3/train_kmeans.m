function [ centroids, feat_to_centroid ] = train_kmeans( features, k_val, max_it )
%TRAIN_KMEANS 
% Groups features into clusters around k centroids.
% features -
%   num_features x descriptor_dimensions(likely 128)

% TODO URGENT: Send in another parameter or add another dimension to
% features matrix that tells label of image set it came from. The output to
% this function will include which labeled sets each word(centroid) belongs
% to.

% Centroids initialized as k random feature points without replacement.
centroids = zeros(k_val,size(features,2));
for i=1:k_val
    chosen_feat = ceil(rand * size(features,1));
    centroids(i,:) = features(chosen_feat,:);
end
centroids = datasample(features,k_val,1,'Replace',false);

converged = false;
% Just in case the centroids don't convergence...
if nargin < 3
    max_it = 50;
end
num_it = 0;

% Index is feature, value is centroid it maps to.
feat_to_centroid = zeros(size(features,1),1);

while ~converged
    % Will be set to false if a change is made.
    old_feat_to_centroid = feat_to_centroid;
    
    

    % For each feature point, match it with the closest centroid.
    for i=1:size(features,1)
            min_dist = Inf;

            for k=1:size(centroids,1)
                % Manhattan distance
                curr_dist = sum(abs(centroids(k,:) - features(i,:)));

                % Euclidean distance
%                 curr_dist = pdist2(centroids(k,:),features(i,:));
                
                % Cosine similarity
%                 curr_dist = acos(dot(centroids(k,:),features(i,:))/(norm(centroids(k,:),2)*norm(features(i,:),2)));
                if curr_dist < min_dist
                    feat_to_centroid(i) = k;
                    min_dist = curr_dist;
                end
            end
    end

    % Stop if cluster components are around same centroids as last time.
    if feat_to_centroid == old_feat_to_centroid
        break;
    end
    
    % New centroids are the mean of components in their cluster.
    for i=1:size(centroids,1)

        feat_avg = zeros(1,size(features,2));
        % How many points belong to centroid i?
        num_points = 0;

        for j=1:size(features,1)
            if feat_to_centroid(j) == i
                feat_avg = feat_avg + features(j,:);
                num_points = num_points + 1;
            end
        end
        
        if num_points > 0
            feat_avg = feat_avg ./ num_points;
            centroids(i,:) = feat_avg;
        end
    end
    
    % TODO find better convergence criteria!
    num_it = num_it + 1;
    disp(num_it);
    
    if num_it >= max_it
        converged = true;
    end
end




