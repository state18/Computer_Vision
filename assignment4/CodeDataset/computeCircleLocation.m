function [circleCenter] = computeCircleLocation(gray_img)

% I was not able to properly get this section working, so it is just a
% guess based on proportions of the image. It is often very accurate though
% to the predictablity of the placement.

[o_rows, o_cols] = size(gray_img);
circleCenter = [ceil(.5 * o_cols),ceil(.35 * o_rows)];

end