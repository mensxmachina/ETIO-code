% Implementation of the Fisher Z test of partial correlation.
% Tests that x is conditionally independent of y given cs using the input
% data.
function [pvalue,stat,df] = linearTest(x, y, cs, data)

if isempty(cs)
    stat = abs(corr(data(:,x),data(:,y)));
else
    corrMatrix = corrcoef(data(:,[x y cs]));
    xyIdx = [1 2];
    csIdx = 3:(size(cs,2)+2);
    residCorrMatrix = corrMatrix(xyIdx, xyIdx) - ...
        corrMatrix(xyIdx, csIdx)*(corrMatrix(csIdx, csIdx)\corrMatrix(csIdx, xyIdx));
    stat = abs(residCorrMatrix(1,2) / sqrt(residCorrMatrix(1,1) * residCorrMatrix(2,2)));
end

df = size(data,1) - size(cs,2) - 3;
pvalue = 2 * tcdf(-abs(sqrt(df) * 0.5*log((1+stat)/(1-stat))), df);
df = size(cs,2);
end