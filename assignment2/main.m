clear all;
close all;

im_path = 'images/IM_%d_%d.jpg';
% How many layers should the pyramid have?
num_pyramids = 6;
% Manually tuned for each image to produce the best looking hybrid image. I
% explain what I consider a "good" hybrid image to be in the report.
stds = [20,6,16,16; 6,4,6,4];

% 4 sets of hybrid images and their pyramids will be produced.
for i=1:4
    % The first image will be the low pass filtered image.
    first_im = rgb2gray(imread(sprintf(im_path,i,1)));
    % The second image will be the high pass filtered image.
    second_im = rgb2gray(imread(sprintf(im_path,i,2)));
    
    [h,w] = size(first_im);
    
    second_im = imresize(second_im,[h,w]);
    
    % Laplacian and Gaussian pyramids are created for each image.
    
    first_gauss_pyramid = cell(num_pyramids,1);
    second_gauss_pyramid = first_gauss_pyramid;
    first_lap_pyramid = first_gauss_pyramid;
    second_lap_pyramid = first_gauss_pyramid;
    
    first_gauss_pyramid{1} = first_im;
    second_gauss_pyramid{1} = second_im;
    
    for j=2:num_pyramids
        [first_gauss_pyramid{j}, first_lap_pyramid{j-1}] = gen_pyramid(first_gauss_pyramid{j-1});
        [second_gauss_pyramid{j}, second_lap_pyramid{j-1}] = gen_pyramid(second_gauss_pyramid{j-1});    
    end
    
    % Combine low pass filtered image 1 and high pass filtered image 2 to get hybrid image.
    hybrid_im = imgaussfilt(first_gauss_pyramid{1},stds(1,i)) + ...
        abs(second_gauss_pyramid{1} - imgaussfilt(second_gauss_pyramid{1},stds(2,i)));
    

    hybrid_pyramid = cell(num_pyramids,1);
    hybrid_pyramid{1} = hybrid_im;
    
    
    % Create hybrid image pyramid for visualization.
    for j=2:num_pyramids
        [hybrid_pyramid{j}, ~] = gen_pyramid(hybrid_pyramid{j-1});
        
%         hFig = figure;
%         set(hFig, 'Position', [500 600 500 600])
%         imshow(hybrid_pyramid{j});
    end
    
end

