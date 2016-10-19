function [ gauss_layer, lap_layer ] = gen_pyramid( im )
%GEN_PYRAMID Generates the next layer of the Gaussian/Laplacian pyramid
%with reduction.

% Blur.
blur_im = imgaussfilt(im);

% Compute Laplacian difference.
lap_layer = abs(im - blur_im);

% Downsample.
gauss_layer = imresize(blur_im,.5);

end

