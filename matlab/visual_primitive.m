classdef visual_primitive
    
    properties
        type char {mustBeMember(type,{'dot','bar','grating','gabor','ripple','flash','square'})} = 'dot'
        interp char {mustBeMember(interp,{'linear','cubic','nearest'})} = 'linear'
        param (:,8) double %[time,x,y,size_x,size_y,angle,spatial_frequency,spatial_phase]
        framerate {mustBeNumeric}
        background {mustBeNumeric}
        foreground {mustBeNumeric}
        X
        Y
    end
    
    methods
        function obj = visual_primitive(X,Y,type,param,framerate,background,foreground,interp)
            obj.type = type;
            obj.param = param;
            obj.framerate = framerate;
            obj.background = background;
            obj.foreground = foreground;
            obj.interp = interp;
            obj.X = X;
            obj.Y = Y;
        end
        
        function movie = create_frames(obj)
            % interpolate points
            P_interp = interp1(obj.param(:,1),obj.param,...
                obj.param(1,1):1/obj.framerate:obj.param(end,1),...
                obj.interp);

            % create movie
            movie = zeros(size(obj.X,1),size(obj.X,2),size(P_interp,1));
            
            resc = @(X,l,h) l+(X-nanmin(X(:))./(nanmax(X(:))-nanmin(X(:)))).*(h-l);
            
            switch(obj.type)
                case 'flash'
                    flash = @(x,y) ones(size(x)); 
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(flash(obj.X,obj.Y),...
                            obj.background,obj.foreground);
                    end
                case 'dot'
                    ellipse = @(x,y,a,b,h,k,theta) ...
                    ((x-h).*cos(theta) + (y-k).*sin(theta)).^2./a.^2 + ...
                    (-(x-h).*sin(theta) + (y-k).*cos(theta)).^2./b.^2 <= 1;
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(ellipse(obj.X,obj.Y,...
                            P_interp(frame,4)./2,P_interp(frame,5)/2,...
                            P_interp(frame,2),P_interp(frame,3),...
                            P_interp(frame,6)),...
                            obj.background,obj.foreground);
                    end
                case 'bar'
                    singleBar = @(x,y,x0,y0,w,h,theta) ...
                    abs(((x-x0).*cos(theta) + (y-y0).*sin(theta))./w + ...
                        (-(x-x0).*sin(theta) + (y-y0).*cos(theta))./h) + ...
                    abs(((x-x0).*cos(theta) + (y-y0).*sin(theta))./w - ...
                        (-(x-x0).*sin(theta) + (y-y0).*cos(theta))./h) <= 1;
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(singleBar(obj.X,obj.Y,...
                            P_interp(frame,2),P_interp(frame,3),...
                            P_interp(frame,4),P_interp(frame,5),...
                            P_interp(frame,6)),...
                            obj.background,obj.foreground);
                    end
                case 'grating'
                    grating = @(x,y,x0,y0,theta,lambda,psi) ...
                    0.5+0.5.*sin(2*pi*1./lambda.*((x-x0).*cos(theta) +  ... 
                        (y-y0).*sin(theta)) + psi);
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(grating(obj.X,obj.Y,...
                            P_interp(frame,2),P_interp(frame,3),...
                            P_interp(frame,6),P_interp(frame,7),...
                            P_interp(frame,8)),...
                            obj.background,obj.foreground);
                    end
                case 'square'
                    square = @(x,y,x0,y0,theta,lambda,psi) ...
                    sin(2*pi*1./lambda.*((x-x0).*cos(theta) +  ... 
                        (y-y0).*sin(theta)) + psi) >= 0;
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(square(obj.X,obj.Y,...
                            P_interp(frame,2),P_interp(frame,3),...
                            P_interp(frame,6),P_interp(frame,7),...
                            P_interp(frame,8)),...
                            obj.background,obj.foreground);
                    end
                case 'gabor'
                    gaborFilter = @(x,y,h,k,lambda,theta,sigma,gamma,psi) ...
                    exp(-(((x-h).*cos(theta) + (y-k).*sin(theta)).^2 + ...
                        gamma.^2.*(-(x-h).*sin(theta)+(y-k).* cos(theta)).^2)./...
                        (2*sigma.^2)) .* ...
                    (0.5+0.5*cos(2*pi*1./lambda.*((x-h).*cos(theta) + ...
                        (y-k).*sin(theta)) + psi));
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(gaborFilter(obj.X,obj.Y,...
                            P_interp(frame,2),P_interp(frame,3),...
                            P_interp(frame,7),P_interp(frame,6),...
                            P_interp(frame,4)/3,P_interp(frame,4)./P_interp(frame,5),...
                            P_interp(frame,8)),...
                            obj.background,obj.foreground);
                    end
                case 'ripple'
                    ripple = @(x,y,x0,y0,a,b,theta,lambda,psi) ...
                    0.5+0.5*sin(2*pi*1./lambda.*sqrt(...
                    ((x-x0).*cos(theta) + (y-y0).*sin(theta)).^2./a.^2 + ...
                    (-(x-x0).*sin(theta) + (y-y0).*cos(theta)).^2./b.^2) + psi);
                    for frame = 1:size(P_interp,1)
                        movie(:,:,frame) = resc(ripple(obj.X,obj.Y,...
                            P_interp(frame,2),P_interp(frame,3),...
                            P_interp(frame,4),P_interp(frame,5),...
                            P_interp(frame,6),P_interp(frame,7),...
                            P_interp(frame,8)),...
                            obj.background,obj.foreground);
                    end
            end
        end
    end
end