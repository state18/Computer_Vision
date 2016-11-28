function [circleCenter,circleRad] = computeCircleLocation(circle_rect,radiusRange)
[rows,cols] = size(circle_rect);



houghVotes = zeros(ceil(rows / 3),ceil(cols / 3),radiusRange(end));

for x = 1:rows
    for y = 1:cols
        
        if ~circle_rect(x,y)
            continue;
        end
        
        for r = radiusRange
            for theta = 0:360
                a = ceil((x - r * cos(theta * pi / 180)) / 3);
                b = ceil((y - r * sin(theta * pi /180)) / 3);
                
                if a > 1 && b > 1 && a <= ceil(rows / 3) && b <= ceil(cols / 3)
                    houghVotes(a,b,r) = houghVotes(a,b,r) + 1;
                end
            end
        end
    end
end

maxVotesVal = max(max(max(houghVotes)));

% Find circle center/radius with most votes.
foundVal = false;
for a=1:size(houghVotes,1)
    for b=1:size(houghVotes,2)
        for r=radiusRange
            if houghVotes(a,b,r) == maxVotesVal
                circleCenter = [a * 3,b * 3];
                circleRad = r;
                foundVal = true;
                break;
            end
        end
        if foundVal
            break;
        end
    end
    if foundVal
        break;
    end
end



end