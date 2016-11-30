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

edge_img = edge(gray_img,'Canny');
binary_img = im2bw(gray_img);

% Replace these with your code
ID = 1;
CP = 123;
HP = 26;
stardust = 600;
level = [327,165];
cir_center = [355,457];

% First step: Define rectangles on the image that encompass key areas such
% as CP, HP, stardust, etc...

% Handle level/circle center detection differently. Use Hough Transform on
% the top portion of the image and locate the semicircle. Then trace along
% the circle and look for when the white line stops. The semi circle
% detection may be used to determine the pixel offset of these boxes, but
% for now I'm just going to use a ballpark number for testing text
% recognition within those boxes.


% % % Circle is believed to be in top half of image.
circle_img = gray_img(ceil(rows * .1):ceil(rows * .40), ceil(cols * .05):ceil(cols * .95)); %edge_img(1:round(rows / 2),:);
% % % Circle is estimated to be 25 to 30% of image size in radius.
% radiusRange = round(size(circle_img,1) * .25 : 2 : size(circle_img,2) * .3);
% [cir_center, circleRadius] = computeCircleLocation(circle_img,radiusRange);


level = computeLevel(gray_img);
% Cutting out the image patches where HP, CP, and stardust is believed to
% be.

% TODO: Possibly use colored information as well to help indicate where the
% desired text is. Pass cropped colored image to the functions below.

% % HP should be 48% to 55% of image size from first row.
% % and 38% to 62% from first column.
hp_img = gray_img(ceil(rows * .48):ceil(rows * .55), ceil(cols * .38):ceil(cols * .62));
hp_img = im2bw(hp_img, graythresh(hp_img));
% % imshow(hp_img);
HP = computeHP(hp_img);
% % 
% % % CP should be 2% to 20% from top, and centered at 28% to 62% vertically
cp_img = gray_img(ceil(rows * .02):ceil(rows * .2), ceil(cols * .28):ceil(cols * .62));
%cp_img = im2bw(cp_img, graythresh(cp_img));
% % % imshow(cp_img);
CP = computeCP(cp_img);

% Stardust should be
sd_img = gray_img(ceil(rows * .7):ceil(rows * .85), ceil(cols * .35):ceil(cols * .8));
%sd_img = im2bw(sd_img, graythresh(sd_img));
% imshow(sd_img);
stardust = computeStardust(sd_img);

% Find the Pokemon's id!
id_img = img(ceil(rows * .15):ceil(rows * .45), ceil(cols * .3):ceil(cols * .7),:);
% Load in training histograms
% trained_hists = load('train_hists.mat');
% trained_hists = trained_hists.labeled_rgb_hists;
ID = computeID(id_img, model);

end
