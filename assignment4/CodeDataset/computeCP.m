function [ CP ] = computeCP( gray_img, char_templates )

% Replace pixels in cutout image that are not "white" enough (wow that
% sounds bad)
binary_img = gray_img > 235;

% Do connected component labeling to pick out individual text characters.
conn_comp = bwconncomp(binary_img);

bounded_imgs = cell(length(conn_comp.PixelIdxList),1);
minMaxReference = zeros(length(bounded_imgs),4);

% Establish a bounding box around each labeled component.
for i=1:length(conn_comp.PixelIdxList)
    % Convert linear indices to image coordinates and find max/min corners.
    [x,y] = ind2sub(size(gray_img), conn_comp.PixelIdxList{i});
    
    minX = min(x);
    maxX = max(x);
    minY = min(y);
    maxY = max(y);
    
    bounded_imgs{i} = binary_img(minX:maxX, minY:maxY);
    minMaxReference(i,:) = [minX,maxX,minY,maxY];

end

% Perform template matching on the bounded labeled components. Try to find
% C and P letters to give us an idea of which ones are relevant. Another
% desirable trait in the numbers we want is being on the same/similar row
% as one another.


fields = fieldnames(char_templates);
closest_matches = cell(length(bounded_imgs),1);

for i=1:length(bounded_imgs)
    minDiff = Inf;
    for j=1:numel(fields)
        char_template = char_templates.(fields{j});
        char_template = char_template{1};
        % Resize to match the template
        resized_template = imresize(char_template, size(bounded_imgs{i}));
        
        % Difference between template and proposed character
        im_diff = sum(sum(abs(logical(resized_template) - bounded_imgs{i})));
        
        if im_diff < minDiff
            minDiff = im_diff;
            closest_matches{i} = fields{j};
        end
        
        
    end
end


% If 'CP' is found, prune out the other characters not near the
% same row as them. 
c_rows = [];
p_rows = [];

for i =1:length(closest_matches)
    if strcmp(closest_matches(i),'c')
        % Note the rows these characters appear on, which is found by using
        % the maximum row of each connected component's bounding box.
        c_rows = [c_rows, minMaxReference(i,2)];
    elseif strcmp(closest_matches(i),'p')
        
        p_rows = [p_rows, minMaxReference(i,2)];
        
    end
    
end


if isempty(c_rows) || isempty(p_rows)
    CP = 1;
    return;
end

rowToKeep = [];
minRowDiff = Inf;
for i=1:length(c_rows)
    % closest p to the c's
    min_pdist = Inf;
    for j=1:length(p_rows)
        distance = abs(p_rows(j) - c_rows(i));
        if distance < min_pdist
            min_pdist = distance;
            closest_p = j;
        end
    end
    
    if min_pdist < .1 * size(gray_img,1)
        rowToKeep = c_rows(i);
        break;
    end
end


% Cut out the connected components that are not very close to the desired
% row.
legal_vals = [];
for i=1:length(bounded_imgs)
    if abs(minMaxReference(i,2) - rowToKeep) > .05 * size(gray_img,1)
        continue;
    end

    
    % Only keep numbers
    switch(closest_matches{i})
        case {'zero','one','two','three','four','five','six','seven','eight','nine'}

        otherwise
            continue;
    end
    legal_vals = [legal_vals, i];
    
    
end


% Now order the found digits by row, to be read as a number.
orderedCP = sortrows([minMaxReference(legal_vals,3), legal_vals(:)]);
CPString = closest_matches(orderedCP(1:end,2));

for i=1:length(CPString)
    CPString(i) = {word2num(CPString{i})};
end
CP = str2double(strjoin(CPString,''));
% Convert from string to a number for this function to return as CP value!


end

