function ssd_people_demo(varargin)
%SSD_PEOPLE_DEMO  Demonstrates the SSD-people detectors on some test images.
%
% SSD_PEOPLE_DEMO('param', value, ...) available parameters:
%
%   'gpu':: []
%   Device index on which to run network. Default value runs the network on
%   the CPU.
%
%   'model':: 'upperbody'
%   Selects which SSD-people model will be used for detections. Available
%   values are 'upperbody' and 'head'.
%
%   'confThr':: 0.3
%   Minimum confidence score between 0 and 1. Detections below this value 
%   will be filtered out.
%
% Example:
%   - ssd_people_demo('gpu',1) -> runs the upperbody detector using
% the GPU available at index 1.
%   - ssd_people_demo('model','head') -> runs the head detector on the CPU.
%
%% Setup dependencies
% Setup matconvnet
% Note that you must add matconvnet's code to your PATH before running this
% code. Example:
%addpath /usr/local/matconvnet-25/matlab;
run vl_setupnn;
% Setup mcnSSD
vl_contrib('setup','mcnSSD');

%% Parameters
opts.gpu = [];
opts.model = 'upperbody';
% opts.model = 'head';
opts.confThr = 0.3;
opts = vl_argparse(opts, varargin);

% Test image paths
images = {
    'data/mounted_police.jpg'
    'data/people_drinking.jpg'
    'data/rugby_players.jpg'
};

% Load the network model
modelPath = sprintf('models/%s-detector.mat', opts.model);
net = Net(load(modelPath));

%% Get predictions for each test image
for i=1:length(images)
    % Read image and resize it to network's input size
    im = single(imread(images{i}));
    im = imresize(im, net.meta.normalization.imageSize(1:2));

    % Evaluate network either on CPU or GPU.
    if numel(opts.gpu) > 0
        gpuDevice(opts.gpu); 
        net.move('gpu'); 
        im = gpuArray(im);
    end

    % Set inputs and run network
    net.eval({'data', im}, 'test');
    preds = net.getValue('detection_out');
    
    % Get predictions sorted by confidence score
    [~, sortedIdx ] = sort(preds(:, 2), 'descend');
    preds = preds(sortedIdx, :);
    
    % Extract the most confident predictions
    keep = find(preds(:,2) >= opts.confThr);
    bboxes = double(preds(keep,3:end));
    scores = preds(keep,2);
    
    % Return image to cpu for visualisation
    if numel(opts.gpu) > 0, im = gather(im); end

    % Diplay predictions
    figure;
    im = im / 255;
    x = bboxes(:,1) * size(im, 2);
    y = bboxes(:,2) * size(im, 1);
    width = bboxes(:,3) * size(im, 2) - x;
    height = bboxes(:,4) * size(im, 1) - y;
    rectangle = [x, y, width, height];
    im = insertShape(im, 'Rectangle', rectangle, 'LineWidth', 2, 'Color', 'yellow');
    str = {};
    for j = 1:length(keep)
        str{j} = sprintf('%.2f', scores(j));
    end
    im = insertText(im, [x, y], str, 'FontSize', 11);
    imagesc(im);
    title(sprintf('SSD-people predictions (top %d are displayed)', ...,
        length(keep)), 'FontSize', 14);
    axis off;
    
    % Free up the GPU allocation
    if numel(opts.gpu) > 0, net.move('cpu'); end
end