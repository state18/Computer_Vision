% Please edit this function only, and submit this Matlab file in a zip file
% along with your PDF report

% Algorithm is loosely commented throughout, but see the attached PDF for
% more details.
function [left_x, right_x, left_y, right_y] = eye_detection(img)
% INPUT: RGB image
% OUTPUT: x and y coordinates of left and right eye.
% Please rewrite this function, and submit this file in Moodle (in a zip file with the report). 


% To reduce processing time and potential false positive detections, chop
% off the margins of the image. Note that later on, the coordinates
% returned from this function must be resized to fit the original image.
img = imgaussfilt(img);
[orig_h,orig_w,~] = size(img);
im_reduct = .15;
img = img(ceil(size(img,1)*im_reduct):ceil(size(img,1)*(1-im_reduct)), ceil(size(img,2)*im_reduct):ceil(size(img,2)*(1-im_reduct)),:);

% Extract edges using Sobel edge detection.
edge_im = edge(im2bw(img));

% Convert to HSV color space.
img = rgb2hsv(img);

crop_h = round(size(img,1)/18);
crop_w = round(size(img,2)/18);

step_size_mult = 10;
best_score = Inf;
scores = Inf*ones(1,3);


% Setup bucket matrix created from earlier training...
bucketMatrix = fill_bucket_matrix;


% Iterate over image and score some cropped images.
for row=1:ceil(crop_h/step_size_mult):size(img,1)
    if row > size(img,1) - crop_h;
        continue;
    end
    
    for col=1:ceil(crop_w/step_size_mult):size(img,2)
        if col > size(img,2) - crop_w;
            continue;
        end
        im_patch = imcrop(img,[col,row,crop_w,crop_h]);
        patch_edges = imcrop(edge_im,[col,row,crop_w,crop_h]);
        score = patch_eval(im_patch,patch_edges,bucketMatrix);
        scores(end+1,:) = [score, row, col];
        if best_score > score
            best_score = score;
        end
    end
end

% The top score is likely one of the eyes. Now find the other one.
scores = sortrows(scores);
top_scoring = scores(1,:);

% Cap the search at 50 to reduce processing time.
if size(scores,1) > 50
    range_to_search = 50;
else
    range_to_search = size(scores,1);
end
pairFound = -1;
for i=2:range_to_search
    % Rows should be about the same for both eyes.
    if abs(top_scoring(2) - scores(i,2)) > size(img,1)/8
        continue;
    end
    % Columns should be roughly between 5 to 30% of image width to each
    % other.
    width_diff = abs(top_scoring(3) - scores(i,3));
    if width_diff > size(img,2) * .8 || width_diff < size(img,2) * .2 
        continue;
    end
    
    pairFound = i;
    break;
end

% Uh oh, no good matches. Guess based on image dimensions. Return.
if pairFound == -1
    left_x = round(size(img,2) * .4 + im_reduct * orig_w);
    left_y = round(size(img,1) * .4 + im_reduct * orig_h);
    
    right_x = round(size(img,2) * .6 + im_reduct * orig_w);
    right_y = round(size(img,1) * .4 + im_reduct * orig_h);
    return;

% Two high scoring matches that are spatially reasonable have been found.
elseif top_scoring(3) > scores(pairFound,3)
    left_eye = scores(pairFound,:);
    right_eye = top_scoring;
else
    left_eye = top_scoring;
    right_eye = scores(pairFound,:);   
end

% Estimation is based on center position of the chosen image patches.
left_x = round(left_eye(3) + crop_w / 2 + im_reduct * orig_w);
left_y = round(left_eye(2) + crop_h / 2 + im_reduct * orig_h);
right_x = round(right_eye(3) + crop_w / 2 + im_reduct * orig_w);
right_y = round(right_eye(2) + crop_h / 2 + im_reduct * orig_h);
end

% Computes a score that tells how likely this image patch is an eye. A
% lower score is better.
function [best_score] = patch_eval(patch,edges,bucketMatrix)
    black = 0;
    white = 0;
    brown = 0;
    red = 0;
    green = 0;
    blue = 0;
    unclassified = 0;

    [h,w,~] = size(patch);

    for x=1:h
        for y=1:w
            hue = patch(x,y,1);
            sat = patch(x,y,2);
            volume = patch(x,y,3);

            % Check for color. Accumulate the corresponding bin.
            % Note: This part was tuned manually and is by no means
            % perfect.
            if volume < .12
                black = black + 1;
            elseif volume >= .7 && sat < .15
                white = white + 1;
            elseif volume < .75 && hue >= .0556 && hue <= .125
               brown = brown + 1;
            elseif hue <= .1389
                red = red + 1;
            elseif hue >= .1527 && hue <= .4306
                green = green + 1;
            elseif hue >= .433 && hue <= .63889
                blue = blue + 1;
            else
                unclassified = unclassified + 1;
            end
        end
    end

    % Normalize to area.

    black = black / (h*w);
    white = white / (h*w);
    brown = brown / (h*w);
    red =  red / (h*w);
    green = green / (h*w);
    blue = blue / (h*w);
    unclassified = unclassified / (h*w);

    
    % Part 2: Edge comparison
    edges = length(find(edges == 1)) / (h*w);
    
    
    % Compare to training data. Take the maximum score out of all the
    % comparisons with sample data.
    best_score = Inf;

    for i=1:length(bucketMatrix)
        score = abs(bucketMatrix(i).black - black) + abs(bucketMatrix(i).white - white) ...
            + abs(bucketMatrix(i).brown - brown) + abs(bucketMatrix(i).red - red) ...
            + abs(bucketMatrix(i).green - green) + abs(bucketMatrix(i).blue - blue) ...
             + 2*abs(bucketMatrix(i).edges - edges);

        if score < best_score
            best_score = score;
        end
    end

end

% Here are some results from my training scripts where patches were taken
% using the ground truth of an image. Brown, green, and blue eyes are
% represented fairly evenly.
function [bucketMatrix] = fill_bucket_matrix()
    bucketMatrix = struct('black',0,'red',0,'green',0, ...
        'blue',0, 'brown',0, 'white',0, 'unclassified',0, 'edges',0);
    
    bucketMatrix(1) = struct('black',0.3064,'red',0.1267,'green',0.0930, ...
        'blue',0.0444, 'brown',0.1900, 'white',0.0448, 'unclassified',0.1948, 'edges',0.0613);
    bucketMatrix(2) = struct('black',0.1496,'red',0.0572,'green',0.1590, ...
        'blue',0.3281, 'brown',0.1263, 'white',0.1590, 'unclassified',0.0207, 'edges',0.0610);
    bucketMatrix(3) = struct('black',0.0214,'red',0.2545,'green',0.0524, ...
        'blue',0.000019602, 'brown',0.4458, 'white',0.0440, 'unclassified',0.1819, 'edges',0.0024);
    bucketMatrix(4) = struct('black',0.0797,'red',0.3435,'green',0.0493, ...
        'blue',0.0095, 'brown',0.4288, 'white',0.0133, 'unclassified',0.0759, 'edges',0.0304);
    bucketMatrix(5) = struct('black',0.0163,'red',0.1182,'green',0.0516, ...
        'blue',0.0163, 'brown',0.2935, 'white',0.0992, 'unclassified',0.4049, 'edges',0);
    bucketMatrix(6) = struct('black',0.3908,'red',0.0043,'green',0.0051, ...
        'blue',0.3361, 'brown',0.0061, 'white',0.1262, 'unclassified',0.1315, 'edges',0.0632);
    bucketMatrix(7) = struct('black',0.2864,'red',0.1091,'green',0.0318, ...
        'blue',0, 'brown',0.4409, 'white',0, 'unclassified',0.1318, 'edges',0.0545);
    bucketMatrix(8) = struct('black',0.2036,'red',0.5945,'green',0.0127, ...
        'blue',0.0327, 'brown',0.0527, 'white',0.0055, 'unclassified',0.0982, 'edges',.1545);
end