function plotboundary(labels, features, model, varargin)

%   Code adapted from: http://openclassroom.stanford.edu/MainFolder/DocumentPage.php?course=MachineLearning&doc=exercises/ex8/ex8.html

%   PLOTBOUNDARY    Plot the SVM classification boundary
%   plotboundary(labels, features, model, fill_on) plots the training data
%   and decision boundary, given a model produced by LIBSVM  
%   The parameter 'fill_on' is a boolean that indicates whether a filled-in
%   contour map should be produced.


% Make classification predictions over a grid of values
rng1 = (max(features(:,1)) - min(features(:,1)))*0.1;
rng2 = (max(features(:,2)) - min(features(:,2)))*0.1;

xplot = linspace(min(features(:,1)) - rng1, max(features(:,1)) + rng1, 200)';
yplot = linspace(min(features(:,2)) - rng2, max(features(:,2)) + rng2, 200)';
[X, Y] = meshgrid(xplot, yplot);
vals = zeros(size(X));
for i = 1:size(X, 2)
   x = [X(:,i),Y(:,i)];
   % Need to use evalc here to suppress LIBSVM accuracy printouts
   [T,predicted_labels, accuracy, decision_values] = ...
       evalc('svmpredict(ones(size(x(:,1))), x, model)');
   clear T;
   vals(:,i) = decision_values;
end

% Plot the SVM boundary
colormap bone
if (size(varargin, 2) == 1) && (varargin{1} == 't')
    contourf(X,Y, vals, 50, 'LineStyle', 'none');
end
contour(X,Y, vals, [0 0], 'LineWidth', 2, 'Color', 'k');
hold on
% Plot the training data on top of the boundary
pos = find(labels == 1);
neg = find(labels == 0);
plot(features(pos,1), features(pos,2), 'ko', 'MarkerFaceColor', 'r');
plot(features(neg,1), features(neg,2), 'ko', 'MarkerFaceColor', 'g')
hold off
