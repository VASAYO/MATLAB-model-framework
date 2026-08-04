classdef ClassVisualizer < handle

properties (SetAccess = private) % Свойства

    % Каталог для сохранения результатов
        SaveDirName  char = 'Results';
    % Имя файла для сохранения результатов, используется как префикс для
    % названий всех создаваемых фигур
        SaveFileName char = '';

    % Ссылки на объекты фигур
        f cell = cell(0);
end

methods % Методы

    function obj = ClassVisualizer(Params)
    % Конструктор

        Common = Params.Common;
        
        obj.SaveDirName  = Common.SaveDirName;
        obj.SaveFileName = Common.SaveFileName;
    end

    function [f, ax] = CreateEmptyAxes(obj, fName)
    % Создание фигуры с пустыми осями для построения графиков
    %
    % f, ax - ссылки на объекты фигуры и осей.

        arguments
            obj   ClassVisualizer;
            fName char = '';
        end

        % Имя фигуры
            if ~isempty(fName)
                fName = sprintf('%s %s', obj.SaveFileName, fName);
            else
                fName = sprintf('%s Figure %d', obj.SaveFileName, length(obj.f)+1);
            end
        % (пере)создадим фигуру с таким именем
            fOpened = findall(0, 'Type', 'figure');
            fOpenedNames = cell(1, length(fOpened));
            for k = 1 : length(fOpened)
                fOpenedNames{k} = fOpened(k).Name;
            end

            if ismember(fName, fOpenedNames)
                close(fOpened(strcmp(fOpenedNames, fName) ) );
            end

            obj.f{end+1}      = figure("Name", fName, "Color", [1 1 1], "WindowStyle", "docked");

            f  = obj.f{end};
            ax = axes();
            grid on; hold on;

        % Удалим ссылки на невалидные объекты
            DeleteInvalidHandles(obj);
    end

    function SaveFigures(obj)
    % Сохранение всех созданных фигур

        % При необходимости создадим папку для сохранения
            if ~exist(obj.SaveDirName, "dir")
                mkdir(obj.SaveDirName);
            end
        % Удалим ссылки на невалидные объекты
            DeleteInvalidHandles(obj);
        
        for k = 1 : length(obj.f)
            fName = get(obj.f{k}, "Name");
            saveas(obj.f{k}, fullfile(obj.SaveDirName, fName), 'fig');
        end
    end

    function CloseFigures(obj)
    % Закрытие всех созданных фигур

        % Удалим ссылки на невалидные объекты
        DeleteInvalidHandles(obj);

        for k = 1 : length(obj.f)
            close(obj.f{k});
        end
        obj.f = cell(0);
    end
end

methods (Access = private) % Приватные методы

    function DeleteInvalidHandles(obj)
    % Удаление ссылок на удалённые/инвалидные фигуры

        isInvalid = false(size(length(obj.f) ) );
        for k = 1 : length(obj.f)
            if ~isvalid(obj.f{k})
                isInvalid(k) = true;
            end
        end
        obj.f(isInvalid) = [];
    end

end
end
