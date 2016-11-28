function [ HP ] = computeHP( img )
%COMPUTEHP Summary of this function goes here
%   Detailed explanation goes here

img = ~img;
% Get binary image for now (use colored later and prune out pixels that are
% not close to the target color of the HP text.
% gray_img = rgb2gray(img);
% binary_img = im2bw(gray_img, graythresh(gray_img));
imshow(img);
% Do connected component labeling to pick out individual text characters.
conn_comp = bwconncomp(img);

bounded_imgs = cell(length(conn_comp.PixelIdxList));
% Establish a bounding box around each labeled component.
for i=1:length(conn_comp.PixelIdxList)
    % Convert linear indices to image coordinates and find max/min corners.
    [x,y] = ind2sub(size(img), conn_comp.PixelIdxList{i});
    
    minX = min(x);
    maxX = max(x);
    minY = min(y);
    maxY = max(y);
    
    bounded_imgs{i} = img(minX:maxX, minY:maxY);
    imshow(bounded_imgs{i});
end

% Perform template matching on the bounded labeled components. Try to find
% H and P letters to give us an idea of which ones are relevant. Another
% desirable trait in the numbers we want is being on the same/similar row
% as one another.




end

