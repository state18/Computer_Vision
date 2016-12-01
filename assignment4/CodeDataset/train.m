
% I compute RGB histograms of training images here.

img_path = './train/';
img_dir = dir([img_path,'*CP*']);
img_num = length(img_dir);


model = struct('id',[],'rgb_hist',[]);
model(img_num) = model(1);

for i = 1:img_num
    
    close all;
    
    img = imread([img_path,img_dir(i).name]);
    
    name = img_dir(i).name;
    
    try
        gray_img = rgb2gray(img);
    catch
        continue;
    end
    [rows,cols] = size(gray_img);
    % Get image patch that encompasses Pokemon.
    ID_img = img(ceil(rows * .15):ceil(rows * .45), ceil(cols * .3):ceil(cols * .7),:);
    
    Red = imhist(ID_img(:,:,1),32);
    Green = imhist(ID_img(:,:,2),32);
    Blue = imhist(ID_img(:,:,3),32);

    % Normalize -
    model(i).id = str2num(name(1:ul_idx(1)-1));
    model(i).rgb_hist = [Red(:), Green(:), Blue(:)] ./ (size(ID_img,1) * size(ID_img,2));

    
end

save('model.mat', 'model');