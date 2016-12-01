function [ID, CP, HP, stardust, level, cir_center] = pokemon_stats (img, model)
% Please DO NOT change the interface
% INPUT: image; model(a struct that contains your classification model, detector, template, etc.)
% OUTPUT: ID(pokemon id, 1-201); level(the position(x,y) of the white dot in the semi circle); cir_center(the position(x,y) of the center of the semi circle)

% One of the images in the validation set crashes the program here because
% it is a weirdly formatted image.
try
gray_img = rgb2gray(img);
[rows,cols] = size(gray_img);
catch 
    ID = 1;
    CP = 1;
    HP = 1;
    stardust = 1;
    level = [1,1];
    cir_center = [1,1]; 
    return;
end


% % HP should be 48% to 55% of image size from first row.
% % and 38% to 62% from first column.
hp_img = gray_img(ceil(rows * .48):ceil(rows * .55), ceil(cols * .38):ceil(cols * .62));
hp_img = im2bw(hp_img, graythresh(hp_img));
HP = computeHP(hp_img, model.char_templates);

% % % CP should be 2% to 20% from top, and centered at 28% to 62% vertically
cp_img = gray_img(ceil(rows * .02):ceil(rows * .2), ceil(cols * .28):ceil(cols * .62));
CP = computeCP(cp_img, model.char_templates);

% Stardust
sd_img = gray_img(ceil(rows * .7):ceil(rows * .85), ceil(cols * .35):ceil(cols * .8));
stardust = computeStardust(sd_img, model.char_templates);

% Find the Pokemon's id!
id_img = img(ceil(rows * .15):ceil(rows * .45), ceil(cols * .3):ceil(cols * .7),:);
ID = computeID(id_img, model.rgb_train);

% Detect semicircle.
cir_center = computeCircleLocation(gray_img);

% Find level circle (smaller one)
level = computeLevel(gray_img);

end



function [ CP ] = computeCP( gray_img, char_templates )

% Replace pixels in cutout image that are not "white" enough (wow that
% sounds bad)
binary_img = gray_img > 235;

% Do connected component labeling to pick out individual text characters.
conn_comp = bwconncomp(binary_img);

bounded_imgs = cell(length(conn_comp.PixelIdxList),1);
minMaxReference = zeros(length(bounded_imgs),4);

% Establish a bounding box around each labeled component.
for i=1:length(conn_comp.PixelIdxList)
    % Convert linear indices to image coordinates and find max/min corners.
    [x,y] = ind2sub(size(gray_img), conn_comp.PixelIdxList{i});
    
    minX = min(x);
    maxX = max(x);
    minY = min(y);
    maxY = max(y);
    
    bounded_imgs{i} = binary_img(minX:maxX, minY:maxY);
    minMaxReference(i,:) = [minX,maxX,minY,maxY];

end

% Perform template matching on the bounded labeled components. Try to find
% C and P letters to give us an idea of which ones are relevant. Another
% desirable trait in the numbers we want is being on the same/similar row
% as one another.


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


% If 'CP' is found, prune out the other characters not near the
% same row as them. 
c_rows = [];
p_rows = [];

for i =1:length(closest_matches)
    if strcmp(closest_matches(i),'c')
        % Note the rows these characters appear on, which is found by using
        % the maximum row of each connected component's bounding box.
        c_rows = [c_rows, minMaxReference(i,2)];
    elseif strcmp(closest_matches(i),'p')
        
        p_rows = [p_rows, minMaxReference(i,2)];
        
    end
    
end


if isempty(c_rows) || isempty(p_rows)
    CP = 1;
    return;
end

rowToKeep = [];
minRowDiff = Inf;
for i=1:length(c_rows)
    % closest p to the c's
    min_pdist = Inf;
    for j=1:length(p_rows)
        distance = abs(p_rows(j) - c_rows(i));
        if distance < min_pdist
            min_pdist = distance;
            closest_p = j;
        end
    end
    
    if min_pdist < .1 * size(gray_img,1)
        rowToKeep = c_rows(i);
        break;
    end
end


% Cut out the connected components that are not very close to the desired
% row.
legal_vals = [];
for i=1:length(bounded_imgs)
    if abs(minMaxReference(i,2) - rowToKeep) > .05 * size(gray_img,1)
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
orderedCP = sortrows([minMaxReference(legal_vals,3), legal_vals(:)]);
CPString = closest_matches(orderedCP(1:end,2));

for i=1:length(CPString)
    CPString(i) = {word2num(CPString{i})};
end
CP = str2double(strjoin(CPString,''));
% Convert from string to a number for this function to return as CP value!
end


function [ HP ] = computeHP( img, char_templates )

img = ~img;

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

end

% Perform template matching on the bounded labeled components. Try to find
% H and P letters to give us an idea of which ones are relevant. Another
% desirable trait in the numbers we want is being on the same/similar row
% as one another.

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

    if minMaxReference(closest_slash,4) > minMaxReference(i,4)
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
end


function [ ID ] = computeID( img, trained_hists )
%COMPUTEID Summary of this function goes here
%   Detailed explanation goes here

% Compute RGB histogram for query image.
Red = imhist(img(:,:,1),32);
Green = imhist(img(:,:,2),32);
Blue = imhist(img(:,:,3),32);

% Normalize -
rgb_hist = [Red(:), Green(:), Blue(:)] ./ (size(img,1) * size(img,2));

% Compare to training histograms.
min_hist_diff = Inf;

for i=1:length(trained_hists)
    curr_hist = trained_hists(i).rgb_hist;
    if isempty(curr_hist)
        continue;
    end
    hist_diff = sum(sum(abs(rgb_hist - curr_hist)));
    if hist_diff < min_hist_diff
        min_hist_diff = hist_diff;
        ID = trained_hists(i).id;
    end
end



end


function [ stardust ] = computeStardust( img, char_templates )

img = img < 170;

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

end

% Perform template matching on the bounded labeled components. Try to find
% double 0's to give us an idea of which ones are relevant. Another
% desirable trait in the numbers we want is being on the same/similar row
% as one another.


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
% same row as them.
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



function [ level ] = computeLevel( gray_img )
% Uses MATLAB's hough circle transform to look for a small circle within the area
% of interest.

[o_rows, o_cols] = size(gray_img);
row_min = .1;
row_max = .4;
col_min = .05;
col_max = .95;
circle_img = gray_img(ceil(o_rows * row_min):ceil(o_rows * row_max), ceil(o_cols * col_min):ceil(o_cols * col_max));

[c_rows, c_cols] = size(circle_img);
radiusRange = round(c_cols * .008 : 1 : c_cols * .02);
% White out the bottom middle area to avoid false positive of pokemon eyes.
circle_img(ceil(c_rows * .45):ceil(c_rows * 1), ceil(c_cols * .2):ceil(c_cols * .8)) = 255;
circle_img(ceil(c_rows * .3):ceil(c_rows * .45), ceil(c_cols * .4):ceil(c_cols * .6)) = 255;

[circles, ~] = imfindcircles(circle_img, [radiusRange(1), radiusRange(end)], 'Sensitivity', .9);

% Initialize, in case no circle was found.
level = [ceil(.5 * o_cols),ceil(.25 * o_rows)];
    
if ~isempty(circles)
    level = circles(1,:);
    % Now, remap the found location to the original image proportions.
    level(1) = level(1) + ceil(col_min * o_cols);
    level(2) = level(2) + ceil(row_min * o_rows);
end

end



% I was not able to properly get this section working, so it is just a
% guess based on proportions of the image. It is often very accurate though
% to the predictablity of the placement.
function [circleCenter] = computeCircleLocation(gray_img)

[o_rows, o_cols] = size(gray_img);
circleCenter = [ceil(.5 * o_cols),ceil(.35 * o_rows)];

end


% Utility Function
function [ num ] = word2num( word )
%WORD2NUM Convert English word to digit string

switch word
    case 'zero'
        num = '0';
    case 'one'
        num = '1';
    case 'two'
        num = '2';
    case 'three'
        num = '3';
    case 'four'
        num = '4';
    case 'five'
        num = '5';
    case 'six'
        num = '6';
    case 'seven'
        num = '7';
    case 'eight'
        num = '8';
    case 'nine'
        num = '9';
    otherwise
        num = 'ERROR';
end
end



