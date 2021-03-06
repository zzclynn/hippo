function grid = makeGabors(m,dims)

dims = [8 8];
grid = zeros(dims(1)^2,m.sources);
seeds(:,1:2) = 1+randn(m.sources,2)/5;
seeds(:,3:5) = rand(m.sources,3); seeds(:,4) = seeds(:,4)*5 + 2;
seeds(:,5) = seeds(:,5)*pi;

for i = 1:m.sources
        temp1 = gabor_fn(seeds(i,1),seeds(i,2),seeds(i,3),seeds(i,4),seeds(i,5),dims(1)) + ...
            + 1i * gabor_fn(seeds(i,1),seeds(i,2),seeds(i,3)+pi/2,seeds(i,4),seeds(i,5),dims(1));
        grid(:,i) = temp1(:);
end

function gb=gabor_fn(bw,gamma,psi,lambda,theta,sz)
% bw    = bandwidth, (1)
% gamma = aspect ratio, (0.5)
% psi   = phase shift, (0)
% lambda= wave length, (>=2)
% theta = angle in rad, [0 pi)
 
sigma = lambda/pi*sqrt(log(2)/2)*(2^bw+1)/(2^bw-1);
sigma_x = sigma;
sigma_y = sigma/gamma;
 
[x y]=meshgrid(linspace(-sz/2,sz/2,sz));%(-fix(sz/2):fix(sz/2),fix(sz/2):-1:fix(-sz/2));
% x (right +)
% y (up +)

% Rotation 
x_theta=x*cos(theta)+y*sin(theta);
y_theta=-x*sin(theta)+y*cos(theta);
 
gb=exp(-0.5*(x_theta.^2/sigma_x^2+y_theta.^2/sigma_y^2)).*cos(2*pi/lambda*x_theta+psi);