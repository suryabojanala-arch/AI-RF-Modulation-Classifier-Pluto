function make_annotated_confusion()
% MAKE_ANNOTATED_CONFUSION  Confusion matrices with the meaning written
% inside every box, for the review slides. Uses the fresh-recording
% results saved by pluto_step7_independent_test.m.

cfg = plutoConfig();
R = load(fullfile(cfg.projectDir, 'data', 'independent_test_results.mat'));
cls = string(cfg.classes);
out = fullfile(cfg.projectDir, 'results');
drawOne(R.Ytrue, R.pA, cls, 'BEFORE fine-tuning: original CNN (trained on RadioML only)', ...
    fullfile(out, 'confusion_original_annotated.png'));
drawOne(R.Ytrue, R.pB, cls, 'AFTER fine-tuning: CNN trained on real Pluto data', ...
    fullfile(out, 'confusion_tuned_annotated.png'));
fprintf('Annotated confusion matrices saved to %s\n', out);
end

function drawOne(yt, yp, cls, ttl, fname)
n = numel(cls);
C = zeros(n);
for i = 1:n
    for j = 1:n
        C(i,j) = sum(yt == cls(i) & yp == cls(j));
    end
end
rowTot  = sum(C, 2);
acc     = diag(C) ./ rowTot * 100;
overall = sum(diag(C)) / sum(C(:)) * 100;

navy = [0.09 0.11 0.30]; blue = [0.23 0.36 0.69]; red = [0.85 0.33 0.25]; grey = [0.40 0.42 0.50];
f = figure('Color', 'w', 'Position', [50 50 1250 1000], 'Theme', 'light');
ax = axes(f, 'Position', [0.01 0.10 0.98 0.78]);
hold(ax, 'on'); axis(ax, 'ij'); axis(ax, 'off');
xlim(ax, [-1.1 n + 2.3]); ylim(ax, [-0.3 n + 1.25]);

for i = 1:n
    for j = 1:n
        v = C(i,j); frac = v / rowTot(i);
        if v == 0
            col = [1 1 1];
        elseif i == j
            col = 1 - (1 - blue) * (0.25 + 0.75 * frac);
        else
            col = 1 - (1 - red) * (0.15 + 0.85 * min(1, frac * 2.5));
        end
        rectangle(ax, 'Position', [j-0.5 i-0.5 1 1], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6]);
        tc = textColour(col, navy);
        if v > 0
            text(ax, j, i - 0.13, sprintf('%d', v), 'HorizontalAlignment', 'center', ...
                'FontSize', 20, 'FontWeight', 'bold', 'Color', tc);
            if i == j
                msg = "correct";
            else
                msg = cls(i) + " called" + newline + cls(j);
            end
            text(ax, j, i + 0.24, msg, 'HorizontalAlignment', 'center', 'FontSize', 9.5, 'Color', tc);
        else
            text(ax, j, i, '0', 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', [0.72 0.72 0.72]);
        end
    end
end

for i = 1:n
    col = 1 - (1 - blue) * (0.25 + 0.75 * acc(i) / 100);
    rectangle(ax, 'Position', [n+0.8 i-0.5 1.3 1], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6]);
    tc = textColour(col, navy);
    text(ax, n + 1.45, i - 0.1, sprintf('%.1f%%', acc(i)), 'HorizontalAlignment', 'center', ...
        'FontSize', 17, 'FontWeight', 'bold', 'Color', tc);
    text(ax, n + 1.45, i + 0.25, 'correct', 'HorizontalAlignment', 'center', 'FontSize', 9.5, 'Color', tc);
end

for k = 1:n
    text(ax, 0.42, k, cls(k), 'HorizontalAlignment', 'right', 'FontSize', 14, 'FontWeight', 'bold', 'Color', navy);
    text(ax, k, n + 0.68, cls(k), 'HorizontalAlignment', 'center', 'FontSize', 14, 'FontWeight', 'bold', 'Color', navy);
end
text(ax, (n + 1) / 2, n + 1.08, 'WHAT THE AI GUESSED  →', 'HorizontalAlignment', 'center', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', blue);
text(ax, -0.85, (n + 1) / 2, 'WHAT WAS REALLY SENT  →', 'HorizontalAlignment', 'center', ...
    'Rotation', -90, 'FontSize', 14, 'FontWeight', 'bold', 'Color', blue);
text(ax, n + 1.45, 0.32, 'Row score', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', navy);
text(ax, (n + 1) / 2, 0.32, 'Each box = number of frames  (1,920 frames sent per row)', ...
    'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', grey);

text(ax, (n + 1) / 2, -0.05, sprintf('%s   |   %.1f%% overall', ttl, overall), ...
    'HorizontalAlignment', 'center', 'FontSize', 15, 'FontWeight', 'bold', 'Color', navy);
annotation(f, 'textbox', [0.02 0.01 0.96 0.07], 'String', ...
    ['Blue diagonal = correct guesses.   Red boxes = mistakes (darker = more).   ' ...
     'Read any box as: "the ROW was sent, the AI said the COLUMN".   White = 0.'], ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', grey);

exportgraphics(f, fname, 'Resolution', 170);
close(f);
end

function tc = textColour(col, navy)
if mean(col) < 0.6, tc = [1 1 1]; else, tc = navy; end
end
