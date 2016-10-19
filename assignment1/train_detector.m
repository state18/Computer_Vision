im_dir = 'train_2';
cropped_dimensions = 'cropped_dims_iris.mat';

imageNames = dir(fullfile(im_dir,'*.jpg'));
imageNames = {imageNames.name}';

imageBuckets = struct('black',0,'red',0,'green',0, ...
    'blue',0, 'brown',0, 'white',0, 'unclassified',0, 'edges',0);

imageBuckets = repmat(imageBuckets,length(imageNames),1);
load(cropped_dimensions);

for im_num=1:length(imageNames)
    % Read in image and convert to HSV color space.
    image = rgb2hsv(imgaussfilt(imread(sprintf('%s/%s',im_dir,imageNames{im_num}))));
    image_patch = imcrop(image,cropped_dims(im_num,:));
    [h,w,~] = size(image_patch);
    
    
    edge_im = edge(im2bw(image));
    % Put each pixel in a color bucket.
    
    % Hue cases:  0-50 = red; 55-155 = green; 156-230 = blue(light); 
    % special cases: volume < .3 = black
    %   volume < .6 and hue = 20-45 = brown
    %   volume > .9 and saturation < .1 deg.. = white
    
    for x = 1:h
        for y = 1:w
            hue = image_patch(x,y,1);
            sat = image_patch(x,y,2);
            volume = image_patch(x,y,3);
            
            % Check for color.
            if volume < .12
                imageBuckets(im_num).black = imageBuckets(im_num).black + 1;
            elseif volume >= .7 && sat < .15
                imageBuckets(im_num).white = imageBuckets(im_num).white + 1;
            elseif volume < .75 && hue >= .0556 && hue <= .125
                imageBuckets(im_num).brown = imageBuckets(im_num).brown + 1;
            elseif hue <= .1389
                imageBuckets(im_num).red = imageBuckets(im_num).red + 1;
            elseif hue >= .1527 && hue <= .4306
                imageBuckets(im_num).green = imageBuckets(im_num).green + 1;
            elseif hue >= .433 && hue <= .63889
                imageBuckets(im_num).blue = imageBuckets(im_num).blue + 1;
            else
                imageBuckets(im_num).unclassified = imageBuckets(im_num).unclassified + 1;
            end
            

        end
    end
    
    % Normalize accumulated color values based on image patch area.
    imageBuckets(im_num).black = imageBuckets(im_num).black / (h*w);
    imageBuckets(im_num).brown = imageBuckets(im_num).brown / (h*w);
    imageBuckets(im_num).red = imageBuckets(im_num).red / (h*w);
    imageBuckets(im_num).green = imageBuckets(im_num).green / (h*w);
    imageBuckets(im_num).blue = imageBuckets(im_num).blue / (h*w);
    imageBuckets(im_num).white = imageBuckets(im_num).white / (h*w);
    imageBuckets(im_num).unclassified = imageBuckets(im_num).unclassified / (h*w);
    
    % Check for edge pixels.
    imageBuckets(im_num).edges = length(find(imcrop(edge_im,cropped_dims(im_num,:))) == 1) / (h*w);
    
end