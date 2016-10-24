function predict_label = your_kNN(feat)
% Output should be a fixed length vector [num of img, 1]. 
% Please do NOT change the interface.

% Input is num_img by numWords histogram representation.

% Load in bags of words from training images.
% needed variable is called labeled_hist_of_words
load model.mat;

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Compute tf and idf weights here. Apply them later.

% query tfs
qtf = ones(size(feat));
idf = ones(1,size(feat,2));
% qtf
for document=1:size(feat,1)
    doc_words = sum(feat(document,:));
%     for word=1:size(feat,2)
%         qtf(document,word) = feat(document,word) ./ doc_words;
%     end
    qtf(document,:) = feat(document,:) ./ doc_words;
end

% training tf
curr_im = 1;
for train_label=1:length(labeled_hist_of_words)
    curr_labeled_set = labeled_hist_of_words{train_label};
    
    for train_doc=1:size(curr_labeled_set,1)
        ttf(curr_im,:) = curr_labeled_set(train_doc,:) ./ sum(curr_labeled_set(train_doc,:));
        curr_im = curr_im + 1;
    end

end

% idf - go through every document including training
for word=1:size(feat,2)
    % # of times word occurs in entire set of documents
    total = 0;
    % # of documents word appears in
    doc_occur = 0;
    
    % Count occurences of word in test documents.
    for document=1:size(feat,1)
        total = total + feat(document,word);
        if feat(document,word) > 0
            doc_occur = doc_occur + 1;
        end
    end
    
    % Count occurences of word in training documents.  
    for train_label=1:length(labeled_hist_of_words)
        curr_labeled_set = labeled_hist_of_words{train_label};
        for train_doc=1:size(curr_labeled_set,1)
            total = total + curr_labeled_set(train_doc, word);
            if curr_labeled_set(train_doc,word) > 0
                doc_occur = doc_occur + 1;
            end
        end
        
    end
    
    idf(word) = log(total / doc_occur);
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% Compare histograms and find k nearest ones.
k = 30;
rgb_weight = 1;
curr_im = 1;
for i=1:size(feat,1)
    % numWords x 2 -> [distanceFromWord, label]
    feat_distances = [];
    rgb_distances = [];
    for j=1:length(labeled_hist_of_words)
        curr_labeled_set = labeled_hist_of_words{j};
        curr_labeled_hist = labeled_rgb_hists{j};
        
        for n=1:size(curr_labeled_set,1)
            
            % TODO: The tf-idf weightings should be done for training set
            % too. idf portion is already done, need to add tf portion to
            % above code when doing tf for query images.
            
            % Manhattan distance
            feat_distances(curr_im,1) = sum(abs(qtf(i,:) .* idf - ttf(curr_im,:) .* idf ));
%             feat_distances(curr_im,1) = sum(abs(feat(i,:) - curr_labeled_set(n,:)));
            
            % Euclidean distance
%             feat_distances(curr_im,1) = pdist2(feat(i,:),curr_labeled_set(n,:));

            % Cosine similarity
%             feat_distances(curr_im,1) = acos(dot(feat(i,:),curr_labeled_set(n,:))/(norm(feat(i,:),2)*norm(curr_labeled_set(n,:),2)));
%               feat_distances(curr_im,1) = acos(dot(qtf(i,:) .* idf,ttf(curr_im,:) .* idf)/(norm(qtf(i,:) .* idf,2)*norm(ttf(curr_im,:) .* idf,2)));

            feat_distances(curr_im,2) = j;
            
            % RGB difference...
            % TODO: Fill in with query RGB histogram...
            query_rgb = 0;
            
            
            rgb_distances(curr_im,1) = sum(abs(query_rgb - curr_labeled_hist(n,:,:) )) .* rgb_weight;
            
            curr_im = curr_im + 1;
        end
    end
    
    % Mix feature bag of words distance with rgb histogram difference.
    feat_distances = feat_distances + rgb_distances;
    
    
    
    
    % Now, determine k closest images.
    [sorted_dist,indx] = sort(feat_distances(:,1),1);
    sorted_dist = [sorted_dist, feat_distances(indx,2)];
    
    predict_label(i) = mode(sorted_dist(1:k,2));
    curr_im = 1;
end

predict_label = predict_label';
% predict_label = mode(feat);
% predict_label = zeros(size(feat,1),1); %dummy. replace it with your own code

end