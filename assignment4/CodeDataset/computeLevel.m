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
radiusRange = round(size(circle_img,2) * .008 : 1 : size(circle_img,2) * .02);
% White out the bottom middle area to avoid false positive of pokemon eyes.
circle_img(ceil(c_rows * .45):ceil(c_rows * 1), ceil(c_cols * .2):ceil(c_cols * .8)) = 255;
circle_img(ceil(c_rows * .3):ceil(c_rows * .45), ceil(c_cols * .4):ceil(c_cols * .6)) = 255;

[circles, ~] = imfindcircles(circle_img, [radiusRange(1), radiusRange(end)]);

% Initialize, in case no circle was found.
level = [ceil(.5 * o_rows),ceil(.5 * o_cols)];
    
if ~isempty(circles)
    level = circles(1,:);
    % Now, remap the found location to the original image proportions.
    level(1) = level(1) + ceil(col_min * o_cols);
    level(2) = level(2) + ceil(row_min * o_rows);
end

end

