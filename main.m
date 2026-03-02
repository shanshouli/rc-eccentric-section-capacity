%1.0 Main program
global Ec fcuk fck fc ac1 ac2 steel Es fy fy1 b h c Ac As  Ra Rb
global strainC strainS yc ys stripe x r

disp('This program calculates the section capacity of eccentrically compressed members with symmetrically reinforced rectangular and annular sections.');

%% Concrete material input
true=1;
fcuk=input('Enter the concrete strength grade: C ');
while true==1
    if (15<=fcuk)&&(fcuk<=50)
        ac1=0.76;
        true=0;
    elseif fcuk>50
        ac1=0.76+(fcuk-50)*(0.82-0.76)/(80-50);
        true=0;
    else
        disp('Invalid concrete strength grade!');
        fcuk=input('Enter the concrete strength grade: C ');
    end

    if (15<=fcuk)&&(fcuk<=40)
        ac2=1.00;
        true=0;
    elseif fcuk>40
        ac2=1.00+(fcuk-40)*(0.87-1.00)/(80-40);
        true=0;
    else
        disp('Invalid concrete strength grade!');
        fcuk=input('Enter the concrete strength grade: C ');
    end
end

fck=0.88*ac1*ac2*fcuk;
fc=round(fck/1.4,1);
Ec=10^2/(2.2+34.7/fcuk);

%% Steel material input
true=1;
steel=input('Enter the reinforcing steel grade: HRB ');
switch steel
    case 335
        fy=300;
    case 400
        fy=360;
    case 500
        fy=435;
    otherwise
        disp('Invalid reinforcing steel grade!');
        steel=input('Enter the reinforcing steel grade: HRB ');
end
Es=2.0e5;
fy1=fy;

%% Section selection
shape=input('Enter the section type number to calculate (1-rectangular; 2-annular): ');

% Calculate the capacity of a rectangular section
if shape==1
    h=input('Enter the rectangular height h (mm) = ');
    b=input('Enter the rectangular width b (mm) = ');

    true=1;
    while true==1
        c=input('Enter the concrete cover thickness (mm) = ');
        d=input('Enter the bar diameter (mm) = ');
        NumS=input('Enter the number of reinforcing bars = ');
        dv=input('Enter the stirrup diameter (mm) = ');
        if b-2*c-NumS*d-2*dv-(NumS-1)*10>0
            true=0;
        else
            disp('The entered reinforcement cannot be arranged. Please re-enter the values.');
        end
    end

    number=input('Enter the number of strip divisions = ');
    h0=h-(c+dv+d/2);
    stripe=h/number;

    Ac=ones(1,number);
    % Store the concrete element area
    for i=1:number
        Ac(i)=Ac(i)*b*stripe;
    end

    % Store the concrete element coordinates
    yc=(-1*h/2+stripe*0.5):stripe:h/2;

    As=ones(1,2);
    % Store the steel element area
    for i=1:2
        As(i)=As(i)*NumS*pi*d*d/4;
    end
    ysi=h/2-c-dv-d/2;
    % Store the steel element coordinates
    ys=[ysi,-1*ysi];

    % Case where the steel first reaches the ultimate tensile strain
    strainC=0:0.00001:0.0033; % Concrete strain at the compression edge
    MN2=zeros(length(strainC),2);  % Initialize the matrix to zero
    for i=1:length(strainC)
        strainS=0.01;
        k=(strainC(i)+strainS)/h0;
        x=h0*strainC(i)/(strainC(i)+strainS);
        r=h/2-x;
        [M,N]=FEAmn(k);
        MN2(i,1)=M;
        MN2(i,2)=N;
    end

    % Concrete reaches the ultimate compressive strain, including full-section compression
    strainS=-fy/Es:0.00001:0.01;
    MN34=zeros(length(strainS),2);
    Mb=0;
    for i=1:length(strainS)
        strainC=0.0033;
        k=(strainS(i)+strainC)/h0;
        x=h0*strainC/(strainS(i)+strainC);
        r=h/2-x;
        [M,N]=FEAmn(k);
        MN34(i,1)=M;
        MN34(i,2)=N;
        if M>Mb
            % Find the limiting axial force Nb
            Mb=M;
            Nb=N;
        end
    end

    % Full-section tension case
    strainC=-fy/Es:0.0001:0;
    MN1=zeros(length(strainC),2);
    for i=1:length(strainC)
        strainS=0.01;
        k=(strainC(i)+strainS)/h0;
        x=h0*strainC(i)/(strainC(i)+strainS);
        r=h/2-x;
        [M,N]=FEAmn(k);
        MN1(i,1)=M;
        MN1(i,2)=N;
    end

% Calculate the capacity of an annular section
elseif shape==2
    Rb=input('Enter the outer annulus radius Rb (mm) = ');
    Ra=input('Enter the inner annulus radius Ra (mm) = ');

    true=1;
    while true==1
        c=input('Enter the concrete cover thickness (mm) = ');
        d=input('Enter the bar diameter (mm) = ');
        dv=input('Enter the stirrup diameter (mm) = ');
        NumS=input('Enter the number of reinforcing bars = ');
        if Rb-Ra-2*c-d-dv>0
            true=0;
        else
            disp('The entered reinforcement cannot be arranged. Please re-enter the values.');
        end
    end

    number=input('Enter the number of strip divisions = ');
    h0=2*Rb-(c+dv+d/2);
    stripe=2*Rb/number;

    Ac=ones(1,number);
    % Store the concrete element area
    for i=1:number
        if (stripe*i>=Rb-Ra)&&(stripe*i<=Rb+Ra)
            Ac(i)=2*Ac(i)*stripe*(sqrt(Rb^2-(Rb-i*stripe)^2)-sqrt(Ra^2-(Ra-i*stripe)^2));
        else
            Ac(i)=2*Ac(i)*stripe*sqrt(Rb^2-(Rb-i*stripe)^2);
        end
    end

    % Store the concrete element coordinates
    yc=(-1*Rb/2+stripe*0.5):stripe:Rb/2;

    As=ones(1,((NumS-2)/2+2));
    % Store the steel element area
    for i=1:((NumS-2)/2+2)
        if i==1||i==((NumS-2)/2+2)
            As(i)=As(i)*pi*d*d/4;
        else
            As(i)=As(i)*2*pi*d*d/4; clc
        end
    end

    theta=ones(1,(NumS-4)/4+1);
    theta0=2*pi/NumS;
    for i=1:((NumS-4)/4+1)
        theta(i)=i*theta0;
    end
    % Store the steel element coordinates
    ys0=(Rb-c-dv-d/2)*sin(theta);
    ys=[ys0,0,-1*ys0];

    % Case where the steel first reaches the ultimate tensile strain
    strainC=0:0.00001:0.0033; % Concrete strain at the compression edge
    MN2=zeros(length(strainC),2);  % Initialize the matrix to zero
    for i=1:length(strainC)
        strainS=0.01;
        k=(strainC(i)+strainS)/h0;
        x=h0*strainC(i)/(strainC(i)+strainS);
        r=Rb/2-x;
        [M,N]=FEAmn(k);
        MN2(i,1)=M;
        MN2(i,2)=N;
    end

    % Concrete reaches the ultimate compressive strain, including full-section compression
    EpsilonY=-fy/Es;
    strainS=EpsilonY:0.00001:0.01;
    MN34=zeros(length(strainS),2);
    Mb=0;
    for i=1:length(strainS)
        strainC=0.0033;
        k=(strainS(i)+strainC)/h0;
        x=h0*strainC/(strainS(i)+strainC);
        r=Rb/2-x;
        [M,N]=FEAmn(k);
        MN34(i,1)=M;
        MN34(i,2)=N;
        if M>Mb
            Mb=M;
            Nb=N;
        end
    end

    % Full-section tension case
    strainC=-fy/Es:0.0001:0;
    MN1=zeros(length(strainC),2);
    for i=1:length(strainC)
        strainS=0.01;
        k=(strainC(i)+strainS)/h0;
        x=h0*strainC(i)/(strainC(i)+strainS);
        r=Rb/2-x;
        [M,N]=FEAmn(k);
        MN1(i,1)=M;
        MN1(i,2)=N;
    end
else
    disp('Invalid section type!');
end

%% Plot and export results
% Plot the result curves
figure()
plot(MN2(:,1),MN2(:,2),'m-');
hold on;
plot(MN34(:,1),MN34(:,2),'k-');
hold on;
plot(MN1(:,1),MN1(:,2),'c-');
title('Nu-Mu Interaction Curve')
xlabel('Mu(kN*m)')
ylabel('Nu(kN)')
hold off

% Combine all Nu and Mu calculation results
all=[MN2;MN34;MN1];

% Sort Nb from small to large
AfterSort=sortrows(all,2);

% Find the index corresponding to Nb-Mb
for i=1:length(AfterSort)
    if AfterSort(i,2)==Nb
        c=i;
    end
end

% Split the two arrays at Nb
nm1=AfterSort(1:c,:);
nm2=AfterSort(c:length(AfterSort),:);

fid=fopen('result.txt','w');
% Write all results to result.txt
fprintf(fid,'%9.4f %9.4f\n',AfterSort');
fclose(fid);

fid=fopen('resultA.txt','w');
% Write the results with N < Nb to resultA.txt
fprintf(fid,'%9.4f %9.4f\n',nm1');
fclose(fid);

fid=fopen('resultB.txt','w');
% Write the results with N > Nb to resultB.txt
fprintf(fid,'%9.4f %9.4f\n',nm2');
fclose(fid);

%1.1 ConstiRelationConcrete.m - Concrete constitutive relationship
function [StressCi] = ConstiRelationConcrete(StrainCi)
% Return the concrete stress value
global fcuk fc

n=2-(fcuk-50)/60;
if n>2
    n=2;
end

EpsilonC0=0.002+0.5*(fcuk-50)*10^(-5);
if EpsilonC0<0.002
    EpsilonC0=0.002;
end

EpsilonCu=0.0033-(fcuk-50)*10^(-5);
if EpsilonCu>0.0033
    EpsilonCu=0.0033;
end

if (StrainCi<=EpsilonC0)&&(StrainCi>=0)
    StressCi=fc*(1-(1-StrainCi/EpsilonC0)^n);
elseif (StrainCi>EpsilonC0)&&(StrainCi<=EpsilonCu)
    StressCi=fc;
else
    StressCi=0;
end
end

%1.2 ConstiRelationSteel.m - Steel constitutive relationship
function [StressSi] = ConstiRelationSteel(StrainSi)
% Return the steel stress value
global Es fy fy1

StressSi=Es*StrainSi;
if StressSi>=fy
    StressSi=fy;
elseif StressSi<(-1)*fy1
    StressSi=-1*fy1;
end
end

%1.3 FEAmn.m - Finite element summation
function [M,N] = FEAmn(k)
% Input the ultimate curvature and return Mu and Nu
global Ac As yc ys r

% Calculate the stress value of each concrete element from curvature
AllStrainC=k*(yc-r);
AllStrainS=-1*k*(ys-r);
AllStressC=zeros(1,length(AllStrainC));
AllStressS=zeros(1,length(AllStrainS));

N=0;
M=0;
% Sum the forces of the concrete elements
for j=1:length(AllStrainC)
    AllStressC(j)=ConstiRelationConcrete(AllStrainC(j));
    N=N+AllStressC(j)*Ac(j);
    M=M+AllStressC(j)*Ac(j)*yc(j);
end

% Sum the forces of the steel elements
for j=1:length(AllStrainS)
    AllStressS(j)=ConstiRelationSteel(AllStrainS(j));
    N=N-AllStressS(j)*As(j);
    M=M-AllStressS(j)*As(j)*ys(j);
end

% Unit conversion
N=N/10^3;
M=M/10^6;
end
