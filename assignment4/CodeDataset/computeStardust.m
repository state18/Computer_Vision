function [ stardust ] = computeStardust( img )
%COMPUTESTARDUST Summary of this function goes here
%   Detailed explanation goes here
stardust = 1;



% img = ~img;

% gray_img = rgb2gray(img);
img = img < 170;
imshow(img);
% Get binary image for now (use colored later and prune out pixels that are
% not close to the target color of the HP text.
% gray_img = rgb2gray(img);
% binary_img = im2bw(gray_img, graythresh(gray_img));
% imshow(img);
% Do connected component labeling to pick out individual text characters.
conn_comp = bwconncomp(img);

bounded_imgs = cell(length(conn_comp.PixelIdxList),1);
minMaxReference = zeros(length(bounded_imgs),4);

% Establish a bounding box around each labeled component.
for i=1:length(conn_comp.PixelIdxList)
    % Convert linear indices to image coordinates and find max/min corners.
    [x,y] = ind2sub(size(img), conn_comp.PixelIdxList{i});
    
    minX = min(x);
    maxX = max(x);
    minY = min(y);
    maxY = max(y);
    
    bounded_imgs{i} = img(minX:maxX, minY:maxY);
    minMaxReference(i,:) = [minX,maxX,minY,maxY];
%     imshow(bounded_imgs{i});
end

% Perform template matching on the bounded labeled components. Try to find
% double 0's to give us an idea of which ones are relevant. Another
% desirable trait in the numbers we want is being on the same/similar row
% as one another.

char_templates = load('char_templates.mat');
char_templates = char_templates.char_templates;

fields = fieldnames(char_templates);
closest_matches = cell(length(bounded_imgs),1);

for i=1:length(bounded_imgs)
    minDiff = Inf;
    for j=1:numel(fields)
        char_template = char_templates.(fields{j});
        char_template = char_template{1};
        % Resize to match the template
        resized_template = imresize(char_template, size(bounded_imgs{i}));
        
        % Difference between template and proposed character
        im_diff = sum(sum(abs(logical(resized_template) - bounded_imgs{i})));
        
        if im_diff < minDiff
            minDiff = im_diff;
            closest_matches{i} = fields{j};
        end
        
        
    end
end


% If 0's are found, prune out the other characters not near the
% same row as them. Also cut out the characters to the right of slash. The
% remaining values read from left to right are the HP value.
zero_rows = [];
zero_doc = [];
for i =1:length(closest_matches)
    if strcmp(closest_matches(i),'zero')
        % Note the rows these characters appear on, which is found by using
        % the maximum row of each connected component's bounding box.
        zero_rows = [zero_rows, minMaxReference(i,2)];
        zero_doc = [zero_doc, i];
    end
    
end

if length(zero_rows) < 2
    stardust = 100;
    return;
end


rowToKeep = [];
minRowDiff = Inf;
for i=1:length(zero_rows)
    % closest 0 to current 0
    min_pdist = Inf;
    for j=1:length(zero_rows)
        if i == j
            continue;
        end
        distance = abs(zero_rows(j) - zero_rows(i));
        if distance < min_pdist
            min_pdist = distance;
            closest_zero = zero_doc(j);
        end
    end
    
    if min_pdist < .1 * size(img,1)
        rowToKeep = zero_rows(i);
        break;
    end
end


% Cut out the connected components that are not very close to the desired
% row.
legal_vals = [];
for i=1:length(bounded_imgs)
    if abs(minMaxReference(i,2) - rowToKeep) > .05 * size(img,1)
        continue;
    end
    
    % Digits should not be far away from where the double zeroes were
    % detected!
    if abs(minMaxReference(i,4) - minMaxReference(closest_zero,4)) > .2 * size(img,2)
        continue;
    end
   
    
    
    % Only keep numbers
    switch(closest_matches{i})
        case {'zero','one','two','three','four','five','six','seven','eight','nine'}

        otherwise
            continue;
    end
    legal_vals = [legal_vals, i];
    
    
end


% Now order the found digits by row, to be read as a number.
orderedStardust = sortrows([minMaxReference(legal_vals,3), legal_vals(:)]);
stardustString = closest_matches(orderedStardust(1:end,2));

for i=1:length(stardustString)
    stardustString(i) = {word2num(stardustString{i})};
end
stardust = str2double(strjoin(stardustString,''));
% Convert from string to a number for this function to return as stardust value!

end

