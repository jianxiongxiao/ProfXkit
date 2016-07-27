function [VMap,NMap,tMap,CMap] = raycastingMEX(camRtC2W, castingRange)

% VMap and NMap are in the world coordinate

% DDA based ray casting

global raycastingDirectionC;
global voxel;
global tsdf_value;
global tsdf_color;

camCenterW = getCameraCenter(camRtC2W);

raycastingDirectionW = transformRTdir(raycastingDirectionC,camRtC2W);

camCenterWgrid = (camCenterW - voxel.range(:,1)) / voxel.unit + 1;

tMap = NaN(1,640*480);
NMap = NaN(3,640*480);
CMap = NaN(3,640*480);


nearPlane = 0.3;
farPlane = 8.0;

step = voxel.unit;
largestep = 0.75 * voxel.mu;

tPrev = 0;

for i=1:(640*480)
    % Ray-Box Intersection to get the range

    origin = camCenterW;
    direction = raycastingDirectionW(:,i);

    % intersect ray with a box
    % http://www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm
    % compute intersection of ray with all six bbox planes
    invR = 1 ./ direction;
    tbot = invR .* (voxel.range(:,1) + repmat(voxel.unit,3,1) - origin);
    ttop = invR .* (voxel.range(:,2) - repmat(voxel.unit,3,1) - origin);

    % re-order intersections to find smallest and largest on each axis
    tmin = min(ttop, tbot);
    tmax = max(ttop, tbot);

    % find the largest tmin and the smallest tmax
    largest_tmin = max(max(tmin(1), tmin(2)), max(tmin(1), tmin(3)));
    smallest_tmax = min(min(tmax(1), tmax(2)), min(tmax(1), tmax(3)));

    % check against near and far plane
    tnear = max(largest_tmin, nearPlane);
    tfar = min(smallest_tmax, farPlane);

    if tnear < tfar
        t = tnear;
        % first walk with largesteps until we found a hit
        stepsize = largestep;
        %f_t = interpolateTrilineary(origin + direction * t);
        f_t = interpolateTrilineary(camCenterWgrid + direction * t / voxel.unit);             

        f_tt = 0;
        if f_t > 0     % ups, if we were already in it, then don't render anything here
            while t < tfar
                %f_tt = interpolateTrilineary(origin + direction * t);
                f_tt = interpolateTrilineary(camCenterWgrid + direction * t / voxel.unit);
                if f_tt < 0                               % got it, jump out of inner loop
                    break;
                end
                if f_tt < 0.8                            % coming closer, reduce stepsize
                    stepsize = step;
                end
                f_t = f_tt;
                t = t + stepsize;
            end
            if f_tt < 0                               % got it, calculate accurate intersection
                tMap(i) = t + stepsize * f_tt / (f_t - f_tt);
            end
        end
    end
end


% normalize normal map
NMap = NMap ./ repmat(sqrt(sum(NMap.^2,1)),3,1);

% computer vertex map
VMap = repmat(camCenterW,1,640*480) + raycastingDirectionW .* (repmat(tMap,3,1));

%imagesc(reshape(tMap,480,640)); axis equal; axis tight

return;








%camCenterWcopy = repmat( (camCenterW - voxel.range(:,1) ) / voxel.unit + 1,1,640*480);
%startPoints = camCenterWcopy + raycastingDirectionW * (castingRange(1)/ voxel.unit);
%endPoints = camCenterWcopy + raycastingDirectionW * (castingRange(2)/ voxel.unit);


% http://stellar.mit.edu/S/course/6/fa10/6.837/courseMaterial/topics/topic1/lectureNotes/13_RayTracing-Acceleration/13_RayTracing-Acceleration.pdf

% we assume the camera must be inside. otherwise, it is an error.
% so we don't test the camera


raycastingDirectionWinv = raycastingDirectionW.^-1;

maxTx = max((voxel.size_grid(1)-2-camCenterWgrid(1))*raycastingDirectionWinv(1,:),(2-camCenterWgrid(1))*raycastingDirectionWinv(1,:));
maxTy = max((voxel.size_grid(2)-2-camCenterWgrid(2))*raycastingDirectionWinv(2,:),(2-camCenterWgrid(2))*raycastingDirectionWinv(2,:));
maxTz = max((voxel.size_grid(3)-2-camCenterWgrid(3))*raycastingDirectionWinv(3,:),(2-camCenterWgrid(3))*raycastingDirectionWinv(3,:));
maxT = min(maxTx, min(maxTy, maxTz));


castingRangeGrid = castingRange/voxel.unit;
maxT = min(maxT, castingRangeGrid(2));




% parallel setting
parallelBlock = matlabpool('size');
blockDim = (640*480)/parallelBlock;
if blockDim ~= round(blockDim)
    error('thread does not align');
end


backMove = voxel.mu_grid;

tMap = NaN(1,640*480);
NMap = NaN(3,640*480);
CMap = NaN(3,640*480);

initDis = 3/ voxel.unit;

% http://www.cse.yorku.ca/~amana/research/grid.pdf
prevT = initDis;

for i=1:(640*480)
    % Ray-Box Intersection to get the range
    
    %{
    raycast( const Volume volume, const uint2 pos, const Matrix4 view, const float nearPlane, const float farPlane, const float step, const float largestep){
        const float3 origin = view.get_translation();
        const float3 direction = rotate(view, make_float3(pos.x, pos.y, 1.f));

        // intersect ray with a box
        // http://www.siggraph.org/education/materials/HyperGraph/raytrace/rtinter3.htm
        // compute intersection of ray with all six bbox planes
        const float3 invR = make_float3(1.0f) / direction;
        const float3 tbot = -1 * invR * origin;
        const float3 ttop = invR * (volume.dim - origin);

        // re-order intersections to find smallest and largest on each axis
        const float3 tmin = fminf(ttop, tbot);
        const float3 tmax = fmaxf(ttop, tbot);

        // find the largest tmin and the smallest tmax
        const float largest_tmin = fmaxf(fmaxf(tmin.x, tmin.y), fmaxf(tmin.x, tmin.z));
        const float smallest_tmax = fminf(fminf(tmax.x, tmax.y), fminf(tmax.x, tmax.z));

        // check against near and far plane
        const float tnear = fmaxf(largest_tmin, nearPlane);
        const float tfar = fminf(smallest_tmax, farPlane);

        if(tnear < tfar) {
            // first walk with largesteps until we found a hit
            float t = tnear;
            float stepsize = largestep;
            float f_t = volume.interp(origin + direction * t);
            float f_tt = 0;
            if( f_t > 0){     // ups, if we were already in it, then don't render anything here
                for(; t < tfar; t += stepsize){
                    f_tt = volume.interp(origin + direction * t);
                    if(f_tt < 0)                               // got it, jump out of inner loop
                        break;
                    if(f_tt < 0.8f)                            // coming closer, reduce stepsize
                        stepsize = step;
                    f_t = f_tt;
                }
                if(f_tt < 0){                               // got it, calculate accurate intersection
                    t = t + stepsize * f_tt / (f_t - f_tt);
                    return make_float4(origin + direction * t, t);
                }
            }
        }
        return make_float4(0);
    }
    %}    
    
    
    
    tMin = castingRangeGrid(1);
    tMax = maxT(i);
    
    if tMin<tMax % max range > min range
        
        tStart = max(castingRangeGrid(1),min(tMax,prevT-backMove));
        
        rayDir = raycastingDirectionW(:,i);
        
        startPoint = camCenterWgrid + rayDir*tStart;
        
        % The initialization phase begins by identifying the voxel in which the ray origin, ?u, is found.
        % If the ray origin is outside the grid, we find the point in which the ray enters the grid and take the adjacent voxel.
        % The integer variables X and Y are initialized to the starting voxel coordinates.
        X = round(startPoint(1));
        Y = round(startPoint(2));
        Z = round(startPoint(3));
        valCurrentVoxel = tsdf_value(X,Y,Z);
        %valCurrentVoxel = interpValue(startPoint);
        
        tOptimal = NaN;
        
        if valCurrentVoxel == 0
            % lucky, you got the surface immediately!
            %tMap(i) = tStart;
            prevT = tStart;
            
            tOptimal = tStart;
        else
            if valCurrentVoxel>0
                localDir = rayDir;
                tMax = tMax-tStart;
                lookforSign = -1;
            else
                localDir = -rayDir;
                tMax = tStart-tMin;
                lookforSign = +1;
            end
            
            % In addition, the variables stepX and stepY are initialized to either 1 or -1 indicating
            % whether X and Y are incremented or decremented as the ray crosses voxel boundaries
            % (this is determined by the sign of the x and y components of ?v).
            stepX = sign(localDir(1));
            stepY = sign(localDir(2));
            stepZ = sign(localDir(3));
            
            % Next, we determine the value of t at which the ray crosses the ?rst vertical voxel boundary
            % and store it in variable tMaxX. We perform a similar computation in y and store the result in tMaxY.
            % The minimum of these two values will indicate how much we can travel along the ray and still remain in the current voxel.
            
            if localDir(1)>0
                tMaxX = (X+0.5 - startPoint(1))/localDir(1);
            elseif localDir(1)<0
                tMaxX = (X-0.5 - startPoint(1))/localDir(1);
            else
                tMaxX = Inf;
            end
            if localDir(2)>0
                tMaxY = (Y+0.5 - startPoint(2))/localDir(2);
            elseif localDir(2)<0
                tMaxY = (Y-0.5 - startPoint(2))/localDir(2);
            else
                tMaxY = Inf;
            end
            if localDir(3)>0
                tMaxZ = (Z+0.5 - startPoint(3))/localDir(3);
            elseif localDir(3)<0
                tMaxZ = (Z-0.5 - startPoint(3))/localDir(3);
            else
                tMaxZ = Inf;
            end
            
            if min(min(tMaxX,tMaxY),tMaxZ)<0
                error('tStart<0');
            end
            
            % Finally, we compute tDeltaX and tDeltaY.
            % tDeltaX indicates how far along the ray we must move (in units of t) for the horizontal component of such a movement to equal the width of a voxel.
            % Similarly,we store in tDeltaY the amount of movement along the ray which has a vertical component equal to the height of a voxel.
            tDeltaX = 1/abs(localDir(1));
            tDeltaY = 1/abs(localDir(2));
            tDeltaZ = 1/abs(localDir(3));
            

            
            t = 0;
            while t<tMax
                if tMaxX < tMaxY
                    if tMaxX < tMaxZ
                        X= X + stepX;
                        tMaxX= tMaxX + tDeltaX;
                    else
                        Z= Z + stepZ;
                        tMaxZ= tMaxZ + tDeltaZ;
                    end
                else
                    if tMaxY < tMaxZ
                        Y= Y + stepY;
                        tMaxY= tMaxY + tDeltaY;
                    else
                        Z= Z + stepZ;
                        tMaxZ= tMaxZ + tDeltaZ;
                    end
                end
                prevT = t;
                t = min(min(tMaxX,tMaxY),tMaxZ);
                
                if tsdf_value(X,Y,Z) * lookforSign > 0
                    
                    if (tsdf_value(X,Y,Z)==-1 && valCurrentVoxel==+1) || (tsdf_value(X,Y,Z)==+1 && valCurrentVoxel==-1)
                        tOptimal = NaN;
                    else
                    
                    
                        % found the zero crossing points!

                        % simplest
                        % tOptimal = t;

                        % simple average
                        tOptimal = (prevT + t)/2;

                        %{
                        % buggy: Ftdt == Ft

                        if lookforSign>0
                            prevTswap = prevT;
                            prevT = t;
                            t= prevTswap;
                        end
                        XYZt   = startPoint + localDir*t;
                        XYZtdt = startPoint + localDir*prevT;

                        Ft = interpolateTrilineary(XYZt(1),XYZt(2),XYZt(3));
                        Ftdt = interpolateTrilineary(XYZtdt(1),XYZtdt(2),XYZtdt(3));

                        tOptimal = t - abs(t-prevT) * Ft / (Ftdt - Ft); 
                        if tOptimal>1000
                            error('tOptimal>1000');
                        end
                        %}

                        %fprintf('i=%d: t=%f tOptimal=%f Ft=%f Ftdt=%f\n',i,t,t - abs(t-prevT) * Ft / (Ftdt - Ft), Ft, Ftdt);
                        tOptimal = tStart - tOptimal * lookforSign;

                        prevT = tOptimal;
                    
                    end
                    break;
                end
                
                valCurrentVoxel = tsdf_value(X,Y,Z);
            end
            
        end
        if ~isnan(tOptimal)
            tMap(i) = tOptimal;

            % compute normal map

            XYZgrid = camCenterWgrid + rayDir*tOptimal;

            NMap(1,i) = interpolateTrilineary(XYZgrid(1)+1,XYZgrid(2),XYZgrid(3))-interpolateTrilineary(XYZgrid(1)-1,XYZgrid(2),XYZgrid(3));
            NMap(2,i) = interpolateTrilineary(XYZgrid(1),XYZgrid(2)+1,XYZgrid(3))-interpolateTrilineary(XYZgrid(1),XYZgrid(2)-1,XYZgrid(3));
            NMap(3,i) = interpolateTrilineary(XYZgrid(1),XYZgrid(2),XYZgrid(3)+1)-interpolateTrilineary(XYZgrid(1),XYZgrid(2),XYZgrid(3)-1);
            
            if ~isempty(tsdf_color)
                CMap(:,i) = interpolateTrilinearyColor(XYZgrid(1),XYZgrid(2),XYZgrid(3));
            end
        end
    end
end

% normalize normal map
NMap = NMap ./ repmat(sqrt(sum(NMap.^2,1)),3,1);

% computer vertex map
VMap = repmat(camCenterW,1,640*480) + raycastingDirectionW .* (repmat(tMap*voxel.unit,3,1));

%imagesc(reshape(tMap,480,640)); axis equal; axis tight

