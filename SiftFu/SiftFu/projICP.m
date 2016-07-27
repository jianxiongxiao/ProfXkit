function camAAr2c = projICP(camAAr2c)

    global VMap;
    global NMap;
    global XYZcamBilateral;
    global NcamBilateral;
    global K;

    global NMapCam;
    global VMapCam;
    global Vku;

    for iterID = 1:10

        %% data association

        % transform the point cloud 

        VMapCam = AngleAxisRotatePoint(camAAr2c, VMap) + repmat(camAAr2c(4:6)',1,size(VMap,2));
        NMapCam = AngleAxisRotatePoint(camAAr2c, NMap);

        % projective association

        px = round(K(1,1)*(VMapCam(1,:)./VMapCam(3,:)) + K(1,3));
        py = round(K(2,2)*(VMapCam(2,:)./VMapCam(3,:)) + K(2,3));
        
        isValid = (1<=px & px <= 640 & 1<=py & py<= 480);
        VMapCam = VMapCam(:,isValid);
        NMapCam = NMapCam(:,isValid);
        px = px(isValid);
        py = py(isValid);
        
        ind = sub2ind([480 640],py,px);
        
        
        %{
        cla(subplot(6,3,12))
        validMap = zeros(480,640);
        validMap(ind) = 1;
        imagesc(validMap);
        axis equal;
        axis tight;
        title(sprintf('Iteration %d: init valid Map',iterID))
        %}
        

        isValid = XYZcamBilateral(640*480*2+ind)~=0;
        VMapCam = VMapCam(:,isValid);
        NMapCam = NMapCam(:,isValid);
        ind = ind(isValid);

        % outlier rejection


        diffD = (VMapCam(1,:) - XYZcamBilateral(ind)).^2 + (VMapCam(2,:) - XYZcamBilateral(640*480+ind)).^2 + (VMapCam(3,:) - XYZcamBilateral(640*480*2+ind)).^2 ;
        dotProdN = sum([NcamBilateral(ind); NcamBilateral(640*480+ind); NcamBilateral(640*480*2+ind)] .* NMapCam,1);

        

        subplot(6,3,17)
        validMap = zeros(480,640);
        validMap(ind) = diffD;
        imagesc(validMap);
        axis equal;
        axis tight;
        title(sprintf('Iteration %d: diffD',iterID))
       
        

        subplot(6,3,18)
        validMap = zeros(480,640);
        validMap(ind) = dotProdN;
        imagesc(validMap);
        axis equal;
        axis tight;
        title(sprintf('Iteration %d: dotProdN',iterID))

        
        
        
        %isValid = (diffD<0.1^2) & (dotProdN > cos(pi/3));
        isValid = (diffD<1^2);
        
        VMapCam = VMapCam(:,isValid);
        NMapCam = NMapCam(:,isValid);
        ind = ind(isValid);
        Vku = [XYZcamBilateral(ind); XYZcamBilateral(640*480+ind); XYZcamBilateral(640*480*2+ind)];

       

        subplot(6,3,15)
        validMap = zeros(480,640);
        validMap(ind) = 1;
        imagesc(validMap);
        axis equal;
        axis tight;
        title(sprintf('Iteration %d: valid Map',iterID))

        
        
        %% optimization
        % objective function
        E = sum(( Vku - VMapCam ) .* NMapCam,1);
        
        

        subplot(6,3,16)
        validMap = zeros(480,640);
        validMap(ind) = E;
        imagesc(validMap);
        axis equal;
        axis tight;
        title(sprintf('Iteration %d: Distance Map',iterID))

        
        
        fprintf('initial error: #inliers = %.2f(%d/%d), sum = %f, mean = %f, median = %f\n', sum(isValid)/length(isValid), sum(isValid), length(isValid), sum(E.^2), mean(E.^2), median(E.^2));


        %options = optimset('Display','iter', 'Algorithm','levenberg-marquardt');
        options = optimset('display','off','Algorithm','levenberg-marquardt');
        [AA_gk, resnorm, residual, exitflag, output] = lsqnonlin(@residualFunction, [0 0 0 0 0 0],[],[],options);


        camAAr2c = cameraRt2AngleAxis(concatenateCameraRt(transformCameraRt(cameraAngleAxis2Rt(AA_gk)), cameraAngleAxis2Rt(camAAr2c)));
    end

end


function residuals = residualFunction(Tgk)
    global NMapCam;
    global VMapCam;
    global Vku;
    
    VkuTran = AngleAxisRotatePoint(Tgk, Vku) + repmat(Tgk(4:6)',1,size(Vku,2));    
    
    residuals = ( VkuTran - VMapCam ) .* NMapCam;
end


%{
% for visualization

figure
image2show = zeros(480,640);
image2show(ind) = distance(1,:);
imagesc(image2show); axis equal; axis tight;
title('Vm(1) - Vd(1)')

figure
image2show = zeros(480,640);
image2show(ind) = distance(2,:);
imagesc(image2show); axis equal; axis tight;
title('Vm(2) - Vd(2)')

figure
image2show = zeros(480,640);
image2show(ind) = distance(3,:);
imagesc(image2show); axis equal; axis tight;
title('Vm(3) - Vd(3)')

figure
image2show = zeros(480,640);
image2show(ind) = sum(distance.^2,1);
imagesc(image2show); axis equal; axis tight;
title('(Vm - Vd)^2')


figure
image2show = zeros(480,640);
image2show(ind) = sum(distance .* NMapCam,1).^2;
imagesc(image2show); axis equal; axis tight;
title('E')



%}


% coarse to fine


