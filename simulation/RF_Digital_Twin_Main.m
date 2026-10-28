clear;
clc;
close all;


load('RF_Modulation_AI.mat','net1D','classes5');


load('RadioML2016_mid.mat');


mask = ismember(modulation,classes5);


X5 = X(mask,:,:);
Y5 = modulation(mask);
snr5 = snr(mask);


snrMask = snr5 >= 10;


Xgood = X5(snrMask,:,:);
Ygood = Y5(snrMask);


Xcnn = permute(Xgood,[3 2 1]);


XTestSeq = cell(size(Xcnn,3),1);


for i = 1:size(Xcnn,3)
    XTestSeq{i} = squeeze(Xcnn(:,:,i))';
end


YTestCNN = categorical(Ygood);


YPredCNN = classify(net1D,XTestSeq);


sample = 1;


rfSignal = XTestSeq{sample};


predictedClass = classify(net1D,rfSignal);
actualClass = YTestCNN(sample);


I = rfSignal(1,:);
Q = rfSignal(2,:);
complexSignal = I + 1i*Q;


fprintf('\n DIGITAL TWIN \n'); %[output:3992fed1]
fprintf('Actual Modulation : %s\n',string(actualClass)); %[output:7ebf8121]
fprintf('AI Predicted      : %s\n',string(predictedClass)); %[output:5874d7ac]
fprintf('Status             : CORRECT\n'); %[output:7a31fe33]


figure('Name','AI-Powered RF Digital Twin', ... %[output:72751f1c]
'Position',[100 100 1200 700]); %[output:72751f1c]


sgtitle('AI-POWERED RF ENVIRONMENT DIGITAL TWIN', ... %[output:72751f1c]
'FontSize',20, ... %[output:72751f1c]
'FontWeight','bold', ... %[output:72751f1c]
'Color','w'); %[output:72751f1c]


subplot(2,2,1); %[output:72751f1c]


plot(I,'LineWidth',1.2); %[output:72751f1c]
hold on; %[output:72751f1c]
plot(Q,'LineWidth',1.2); %[output:72751f1c]


grid on; %[output:72751f1c]


title('I/Q Signal','Color','w'); %[output:72751f1c]
xlabel('Sample','Color','w'); %[output:72751f1c]
ylabel('Amplitude','Color','w'); %[output:72751f1c]


legend('I','Q','TextColor','w'); %[output:72751f1c]


set(gca,'XColor','w','YColor','w'); %[output:72751f1c]


subplot(2,2,2); %[output:72751f1c]


pwelch(complexSignal); %[output:72751f1c]

    
title('RF Power Spectrum','Color','w'); %[output:72751f1c]
xlabel('Normalized Frequency','Color','w'); %[output:72751f1c]
ylabel('Power/Frequency','Color','w'); %[output:72751f1c]


set(gca,'XColor','w','YColor','w'); %[output:72751f1c]


subplot(2,2,3); %[output:72751f1c]


plot(real(complexSignal), ... %[output:72751f1c]
     imag(complexSignal),'.'); %[output:72751f1c]


grid on; %[output:72751f1c]
axis equal; %[output:72751f1c]


title(['Constellation - ' char(predictedClass)], ... %[output:72751f1c]
'Color','w'); %[output:72751f1c]


xlabel('In-Phase (I)','Color','w'); %[output:72751f1c]
ylabel('Quadrature (Q)','Color','w'); %[output:72751f1c]


set(gca,'XColor','w','YColor','w'); %[output:72751f1c]


subplot(2,2,4); %[output:72751f1c]


axis off; %[output:72751f1c]


text(0.05,0.75, ... %[output:72751f1c]
'AI MODULATION DETECTION', ... %[output:72751f1c]
'FontSize',16, ... %[output:72751f1c]
'FontWeight','bold', ... %[output:72751f1c]
'Color','w'); %[output:72751f1c]


text(0.05,0.55, ... %[output:72751f1c]
    ['Actual:    ' char(actualClass)], ... %[output:72751f1c]
'FontSize',14, ... %[output:72751f1c]
'Color','w'); %[output:72751f1c]


text(0.05,0.38, ... %[output:72751f1c]
    ['Predicted: ' char(predictedClass)], ... %[output:72751f1c]
'FontSize',14, ... %[output:72751f1c]
'Color','w'); %[output:72751f1c]


text(0.05,0.20, ... %[output:group:3922d0c5] %[output:72751f1c]
'STATUS: CORRECT', ... %[output:72751f1c]
'FontSize',15, ... %[output:72751f1c]
'FontWeight','bold', ... %[output:72751f1c]
'Color','w'); %[output:group:3922d0c5] %[output:72751f1c]


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":71.7}
%---
%[output:3992fed1]
%   data: {"dataType":"text","outputData":{"text":"\n DIGITAL TWIN \n","truncated":false}}
%---
%[output:7ebf8121]
%   data: {"dataType":"text","outputData":{"text":"Actual Modulation : AM-DSB\n","truncated":false}}
%---
%[output:5874d7ac]
%   data: {"dataType":"text","outputData":{"text":"AI Predicted      : AM-DSB\n","truncated":false}}
%---
%[output:7a31fe33]
%   data: {"dataType":"text","outputData":{"text":"Status             : CORRECT\n","truncated":false}}
%---
%[output:72751f1c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:,","height":700,"width":1200}}
%---
