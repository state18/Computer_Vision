img_path = './train/';
img_dir = dir([img_path,'*CP*']);
img_num = length(img_dir);
% load ('./model.mat');

ID_gt = zeros(img_num,1);
CP_gt = zeros(img_num,1);
HP_gt = zeros(img_num,1);
stardust_gt = zeros(img_num,1);
ID = zeros(img_num,1);
CP = zeros(img_num,1);
HP = zeros(img_num,1);
stardust = zeros(img_num,1);


model = struct('id',[],'rgb_hist',[]);
model(img_num) = model(1);

for i = 1:img_num
    
    close all;
    
    img = imread([img_path,img_dir(i).name]);
    
    % get ground truth annotation from image name
    name = img_dir(i).name;
%     ul_idx = findstr(name,'_'); 
%     ID_gt(i) = str2num(name(1:ul_idx(1)-1));
%     CP_gt(i) = str2num(name(ul_idx(1)+3:ul_idx(2)-1));
%     HP_gt(i) = str2num(name(ul_idx(2)+3:ul_idx(3)-1));
%     stardust_gt(i) = str2num(name(ul_idx(3)+3:ul_idx(4)-1));
    
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
%     [ID(i), CP(i), HP(i), stardust(i), level, cir_center] = pokemon_stats (img, model);
    
%     imshow(img); hold on;
%     plot(level(1),level(2),'b*');
%     plot(cir_center(1),cir_center(2),'g^');
    
end

save('model.mat', 'model');