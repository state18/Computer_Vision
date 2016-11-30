function [ HP ] = computeHP( img )
%COMPUTEHP Summary of this function goes here
%   Detailed explanation goes here

img = ~img;
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
% H and P letters to give us an idea of which ones are relevant. Another
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

% If HP and slash are found, prune out the other characters not near the
% same row as them. Also cut out the characters to the right of slash. The
% remaining values read from left to right are the HP value.
h_rows = [];
p_rows = [];
slash_rows = [];
slashes = [];
for i =1:length(closest_matches)
    if strcmp(closest_matches(i),'h')
        % Note the rows these characters appear on, which is found by using
        % the maximum row of each connected component's bounding box.
        h_rows = [h_rows, minMaxReference(i,2)];
    elseif strcmp(closest_matches(i),'p')
        
        p_rows = [p_rows, minMaxReference(i,2)];
        
    elseif strcmp(closest_matches(i),'slash')
        
        slash_rows = [slash_rows,minMaxReference(i,2)];
        slashes = [slashes, i];
    end
    
end

% My method fails if it cannot detect a slash anywhere. Returning 1 here
% to not break the interface and crash the program...
if isempty(slashes) || isempty(h_rows) || isempty(p_rows)
    HP = 1;
    return;
end

rowToKeep = [];
minRowDiff = Inf;
for i=1:length(h_rows)
    % closest p
    min_pdist = Inf;
    for j=1:length(p_rows)
        distance = abs(p_rows(j) - h_rows(i));
        if distance < min_pdist
            min_pdist = distance;
            closest_p = j;
        end
    end
    % closest slash
    min_slashdist = Inf;
    for k=1:length(slash_rows)
        distance = abs(slash_rows(k) - h_rows(i));
        if distance < min_slashdist
            min_slashdist = distance;
            closest_slash = slashes(k);
        end
    end
    
    if min_pdist < .1 * size(img,1) && min_slashdist < .1 * size(img,1)
        rowToKeep = h_rows(i);
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

    if minMaxReference(closest_slash,4) < minMaxReference(i,4)
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
orderedHP = sortrows([minMaxReference(legal_vals,3), legal_vals(:)]);
HPString = closest_matches(orderedHP(1:end,2));

for i=1:length(HPString)
    HPString(i) = {word2num(HPString{i})};
end
HP = str2double(strjoin(HPString,''));
% Convert from string to a number for this function to return as HP value!



