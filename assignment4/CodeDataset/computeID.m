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

