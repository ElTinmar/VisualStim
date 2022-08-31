classdef flatProjection
    
    properties
        dw          % distance between fish and glass
        cx          % px/mm x
        cy          % px/mm y
        x_zero      % zero x axis in px
        y_zero      % zero y axis in px
        theta_range % range for theta
        phi_range   % range for phi
        x_range     % range for x
        y_range     % range for y
    end
    
    methods
        function obj = flatProjection(dw,cx,cy,x_zero,y_zero)
            if nargin ~= 5
                error('Wrong number of arguments');
            end
            
            obj.dw = dw;
            obj.cx = cx;
            obj.cy = cy;
            obj.x_zero = x_zero;
            obj.y_zero = y_zero;
            obj.theta_range = [-pi/3 pi/3];
            obj.phi_range = [-pi/3 pi/3];
            obj.x_range = [-Inf Inf];
            obj.y_range = [-Inf Inf];
        end
        
        function x = get_x(obj,theta)
            x = NaN(size(theta));
            ind_valid = find((theta >= obj.theta_range(1)) & (theta <= obj.theta_range(2)));
            x(ind_valid) = obj.cx*obj.dw*tan(theta(ind_valid)) + obj.x_zero;
        end
        
        function y = get_y(obj,phi)
            y = NaN(size(phi));
            ind_valid = find(phi >= obj.phi_range(1) & phi <= obj.phi_range(2));
            y(ind_valid) = obj.cy*obj.dw*tan(phi(ind_valid)) + obj.y_zero;
        end
        
        function theta = get_theta(obj,x)
            theta = NaN(size(x));
            ind_valid = find((x >= obj.x_range(1)) & (x <= obj.x_range(2)));
            theta(ind_valid) = atan2(x(ind_valid)-obj.x_zero,obj.cx*obj.dw);
        end
        
        function phi = get_phi(obj,y,x)
            phi = NaN(size(y));
            ind_valid = find((y >= obj.y_range(1)) & (y <= obj.y_range(2)));
            phi(ind_valid) = atan2(y(ind_valid)-obj.y_zero,obj.cy*obj.dw);
        end
    end
end
