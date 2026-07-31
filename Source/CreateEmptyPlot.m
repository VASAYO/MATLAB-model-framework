function [f, ax] = CreateEmptyPlot(FigureName)

arguments
    FigureName char = [];
end

if ~isempty(FigureName)
% Если фигура с заданным именем уже существует, пересоздадим её

    figures = findall(0, 'Type', 'figure');
    figuresNames = cell(1, length(figures));
    for k = 1 : length(figures)
        figuresNames{k} = figures(k).Name;
    end
    if ismember(FigureName, figuresNames)
        close(figures(strcmp(figuresNames, FigureName) ) );
    end

    f = figure(Name=FigureName, Color=[1 1 1], WindowStyle="docked");
    ax = axes();

else
% Иначе просто создадим новую фигуру

    f = figure(Color=[1 1 1], WindowStyle="docked");
    ax = axes();
end

hold on; grid on;
