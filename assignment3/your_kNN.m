function predict_label = your_kNN(feat)
% Output should be a fixed length vector [num of img, 1]. 
% Please do NOT change the interface.

% Input is num_img by numWords histogram representation.

% Load in bags of words from training images.
% needed variable is called labeled_hist_of_words
load model.mat;
load rgb_hists.mat;

% In the 'test' script, feature_extraction is called once to determine the
% size of the word histograms. Doing this causes an extra unwanted
% histogram. It is cut out here.
rgb_hists = rgb_hists(2:end,:,:);
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Compute tf and idf weights here. Apply them later.

% query tfs
qtf = ones(size(feat));
idf = ones(1,size(feat,2));
% qtf
for document=1:size(feat,1)
    doc_words = sum(feat(document,:));
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
k = 10;
rgb_weight = 1;
curr_im = 1;
for i=1:size(feat,1)

    feat_distances = [];
    rgb_distances = [];
    for j=1:length(labeled_hist_of_words)
        curr_labeled_set = labeled_hist_of_words{j};
        curr_labeled_hist = labeled_rgb_hists{j};
        
        for n=1:size(curr_labeled_set,1)
            
            
            % Distances between query image bag of words i and all training
            % images
            feat_distances(curr_im,1) = sum(abs(qtf(i,:) .* idf -  ttf(curr_im,:) .* idf ));
            feat_distances(curr_im,2) = j;
            
            
            
                        
            % Compare query image RGB hist to train RGB hist...
            rgb_distances(curr_im,1) = sum(sum(abs(rgb_hists(i,:,:) - curr_labeled_hist(n,:,:)))) .* rgb_weight;
            rgb_distances(curr_im,2) = j;
            
            curr_im = curr_im + 1;
        end
    end
    
    
    
    % Now, determine k closest images in terms of bag of words.
    [sorted_dist,indx] = sort(feat_distances(:,1),1);
    sorted_dist = [sorted_dist, feat_distances(indx,2)];
    
    % Sort rgb histograms too, same as above.
    [sorted_dist_rgb,indx] = sort(rgb_distances(:,1),1);
    sorted_dist_rgb = [sorted_dist_rgb, rgb_distances(indx,2)];
    
    % Choose k nearest features and k nearest features and pool them
    % together. The label that appears the most is chosen.
    label_votes = zeros(30,1);
    curr_winner = 1;
    
    for all_dist=1:k*2
        if mod(all_dist,2) == 0
            % Count next closest RGB distance
            curr_label = sorted_dist_rgb(all_dist / 2,2);
            
        else
            % Count next closest bag of words distance
            curr_label = sorted_dist(all_dist,2);
        end
        % Check to see if a label has taken the lead.
        label_votes(curr_label) = label_votes(curr_label) + 1;
        if label_votes(curr_label) > label_votes(curr_winner)
            curr_winner = curr_label;
        end
    end
    
    predict_label(i) = curr_winner;
    curr_im = 1;
end

% Delete rgb histogram data file, so it doesn't interfere with any future
% runs of the algorithm. I know it's bad form, but some fancy footwork was
% needed to keep the same interface of the skeleton code.

delete('rgb_hists.mat');

predict_label = predict_label';

end