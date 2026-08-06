classdef ClassSaveResults < handle
% Класс для сохранения результатов моделирования

properties (SetAccess = private) % Свойства
    
    % Имя папки для сохранения
        SaveDirName;
    % Имя файла для сохранения результата и лога
        SaveFileName;
end

methods % Методы
    function obj = ClassSaveResults(Params)
    % Конструктор

        % Инициализация параметров
            Common = Params.Common;
            obj.SaveDirName  = Common.SaveDirName;
            obj.SaveFileName = Common.SaveFileName;
    end

    function Step(obj, varargin)
    % Сохранение результатов

        % Если папки с результатами не существует, создадим её
        if exist(obj.SaveDirName, "dir") ~= 7
            mkdir(obj.SaveDirName);
        end

        % Сохраним переменные в .mat-файл
        vars2Save = struct;
        for k = 2 : nargin
            if isempty(inputname(k)), continue; end
            vars2Save.(inputname(k)) = varargin{k-1};
        end
        save(fullfile(obj.SaveDirName, obj.SaveFileName), '-struct', "vars2Save");
    end
end
end
