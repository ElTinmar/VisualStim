classdef cylinderProjection
    
    properties
        d           % distance between proj and chamber in mm
        r           % radius of chamber in mm
        cx          % px/mm x
        cy          % px/mm y
        x_zero      % zero x axis in px
        y_zero      % zero y axis in px
        y_fish      % fish y axis position in px
        theta_range % range for theta
        phi_range   % range for phi
        x_range     % range for x
        y_range     % range for y
    end
    
    methods
        function obj = cylinderProjection(d,r,cx,cy,x_zero,y_zero,y_fish)
            if nargin ~= 7
                error('Wrong number of arguments');
            end
            
            obj.d = d;
            obj.r = r;
            obj.cx = cx;
            obj.cy = cy;
            obj.x_zero = x_zero;
            obj.y_zero = y_zero;
            obj.y_fish = y_fish;
            obj.theta_range = [-acos(r/(d + r)) acos(r/(d + r))];
            obj.phi_range = [-pi/2 pi/2];
            obj.x_range = [-cx*r*sqrt(d/(d+2*r))+x_zero cx*r*sqrt(d/(d+2*r))+x_zero];
            obj.y_range = [-Inf Inf];
        end
        
        function x = get_x(obj,theta)
            x = NaN(size(theta));
            ind_valid = find((theta >= obj.theta_range(1)) & (theta <= obj.theta_range(2)));
            x(ind_valid) = obj.cx*obj.d*obj.r*sin(theta(ind_valid))./(obj.d + obj.r*(1-cos(theta(ind_valid)))) + obj.x_zero;
        end
        
        function y = get_y(obj,theta,phi)
            if ~isequal(size(theta),size(phi))
                error('Theta and phi should have compatible sizes')
            end
            y = NaN(size(theta));
            ind_valid = find(theta >= obj.theta_range(1) &...
                theta <= obj.theta_range(2) &...
                phi >= obj.phi_range(1) &...
                phi <= obj.phi_range(2));
            y(ind_valid) = obj.cy*(obj.d*(obj.r*tan(phi(ind_valid))+(obj.y_fish-obj.y_zero)/obj.cy)./(obj.d + obj.r*(1-cos(theta(ind_valid))))) + obj.y_zero;
        end
        
        function theta = get_theta(obj,x,y)
            theta = NaN(size(x));
            ind_valid = find((x >= obj.x_range(1)) & (x <= obj.x_range(2)));
            theta(ind_valid) = atan2(obj.cx*obj.d*(x(ind_valid)-obj.x_zero)*(obj.d+obj.r)-(x(ind_valid)-obj.x_zero).*sqrt(-(x(ind_valid)-obj.x_zero).^2*(obj.d+obj.r)^2+obj.cx^2*obj.d^2*obj.r^2+obj.r^2*(x(ind_valid)-obj.x_zero).^2),...
                (x(ind_valid)-obj.x_zero).^2*(obj.d+obj.r) + obj.cx*obj.d*sqrt(-(x(ind_valid)-obj.x_zero).^2*(obj.d+obj.r)^2 + obj.cx^2*obj.d^2*obj.r^2 + obj.r^2*(x(ind_valid)-obj.x_zero).^2));
        end
        
        function phi = get_phi(obj,x,y)
            if ~isequal(size(y),size(x))
                error('y and x should have compatible sizes')
            end
            phi = NaN(size(y));
            ind_valid = find(x >= obj.x_range(1) &...
                x <= obj.x_range(2) &...
                y >= obj.y_range(1) &...
                y <= obj.y_range(2));
            phi(ind_valid) = -atan(((obj.y_fish - obj.y_zero)./obj.cy - ((y(ind_valid) - obj.y_zero).*(obj.d - obj.r*(cos(obj.get_theta(x(ind_valid))) - 1)))./(obj.cy*obj.d))./obj.r);
        end
    end
end
