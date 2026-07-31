function Main(varargin)
% Главная исполняемая функция модели
% 
% Name-value параметры:
%   "Path2SetupList" - (опционально) путь к папке, .mat или .m-файлу, 
%                      содержащему наборы параметров для моделирования. В
%                      отсутствии данного параметра модель выполняет
%                      моделирование для всех найденных наборов параметров 
%                      в папке Setups или корневой папке модели;
% 
%   "isPause2SelectParams" - флаг необходимости остановки модели перед
%                            началом работы, чтобы выбрать в консоли наборы
%                            параметров, для которых необходимо выполнить 
%                            моделирование: 'false' | 'true'.

    % Укажите список путей, которые необходимо включить для выполнения
    % моделирования
        Paths = { ...
            'Source' ...
            };

    % Парсинг name-value параметров
        Path2SetupList = '';
        isPause2SelectParams = false;
        k = 1;
        while k <= length(varargin)

            if strcmpi(varargin{k}, 'Path2SetupList')
                Path2SetupList = char(varargin{k+1});
                k = k + 2;
                continue;
            end

            if strcmpi(varargin{k}, 'isPause2SelectParams')
                if strcmpi(varargin{k+1}, 'true')
                    isPause2SelectParams = true;
                end
                k = k + 2;
                continue;
            end
            k = k + 1;
        end        

    % Подготовка к работе
        clc;
        % Добавление путей и их удаление при завершении работы функции
            ProcessPaths(Paths, 'add');
            Paths = HandleContainer(Paths);
        % Флаг того, ведётся ли в данный момент моделирование
            isModeling = HandleContainer(false);
        % Объект, вызывающий специальную функцию при завершении работы
            ShutdownObj = onCleanup(@() ShutdownFun(Paths, isModeling));

    % Получим список полей структуры параметров
        [~, FNames] = SetParams([], 0);

    % Получение наборов параметров для моделирования
        if isempty(Path2SetupList)
        % Если входной аргумент не задан, выполним поиск параметров из
        % мест по умолчанию

            ParamsSets = ReadSetup(FNames, 'Russian');

        elseif exist(Path2SetupList, "dir") || ...
                exist(Path2SetupList, "file") && isequal(Path2SetupList(end-1:end), '.m')
        % Если входной аргумент указывает на каталог или сетап-лист,
        % найдём и считаем все наборы параметров из указанного пути

            ParamsSets = ReadSetup(FNames, 'Russian', Path2SetupList);

        elseif exist(Path2SetupList, "file") && isequal(Path2SetupList(end-3:end), '.mat')
        % Если входной аргумент указывает на .mat-файл, считаем набор
        % параметров из него

            ParamsFromMat = load(Path2SetupList, 'Params');
            if isfield(ParamsFromMat, 'Params')
                ParamsSets = {ParamsFromMat.Params};
                fprintf('%s Из файла %s считано 1 наборов параметров.\n\n', ...
                    datetime, Path2SetupList);
                clear ParamsFromMat;

            else
                error('Файл %s не содержит структуры параметров.', Path2SetupList);
            end
        end

    % Дополним каждый набор значениями по умолчанию, после чего выполним
    % проверку корректности наборов
    for k = 1 : length(ParamsSets)

        % Установка значений по умолчанию
        ParamsSets{k} = SetParams(ParamsSets{k}, k);

        % Проверка корректности параметров
        ParamsSets{k} = CalcAndCheckParams(ParamsSets{k}, k);
    end

    % При необходимости предложим пользователю выбрать наборы параметров
    % для моделирования
    if isPause2SelectParams

        % Выведем список кандидатов для моделирования
            fprintf('Список найденных наборов параметров:\n');
            for k = 1 : length(ParamsSets)
                fprintf('  %2d. %s\n', k, ...
                    fullfile(ParamsSets{k}.Common.SaveDirName, ...
                             ParamsSets{k}.Common.SaveFileName) );
            end

        % Приглашение ввести номера наборов параметров
            kVals = input(['\nВведите номера наборов параметров ' ...
                'для моделирования в виде вектора чисел:\n'], 's');
            eval(['kVals = [' kVals '];']);

        % Оставим лишь выбранные наборы
            ParamsSets = ParamsSets(kVals);
    end

    % Цикл по наборам параметров
    for k = 1 : length(ParamsSets)

        % Текущий набор параметров
            Params = ParamsSets{k};

        % Создадим папку, в которую будут сохранены результаты
            if ~exist(Params.Common.SaveDirName, "dir")
                mkdir(Params.Common.SaveDirName);
            end

        % Включим логгирование
            logFileName = fullfile(Params.Common.SaveDirName, [Params.Common.SaveFileName '.log']);
            if exist(logFileName, "file")
                delete(logFileName);
            end
            diary(logFileName);

        % Лог
            fprintf('%s Моделирование набора параметров ''%s'' (%d из %d) ...\n', ...
                datetime, Params.Common.SaveFileName, k, numel(ParamsSets) );

        % Флаг моделирования
            isModeling.Value = true;

        % Пробуем выполнить моделирование и сохранить результаты
        try

            % Инициализация объектов
            Objs = PrepareObjects(Params);

            % Выполнение моделирования
            [Objs, SimData] = MainChain(Objs, Params);

            % Обработка результатов моделирования

            % Сохранение результатов 
            % 
            % Аргументами должны быть ПЕРЕМЕННЫЕ, которые будут сохранены 
            % в файл. Поданные в качестве аргументов константы/выражения
            % будут проигнорированы
            Objs.SaveResults.Step(Params, 'Тут могут быть перечисленны другие переменные для сохранения');

            % Удаление объектов
            DeleteObjects(Objs);

        % Если поймали ошибку, занесём её в лог, после чего перейдём к
        % новому набору параметров
        catch ME

            % Флаг моделирования
                isModeling.Value = false;
            % Лог ошибки
                fprintf('%s     Не завершено:\n', datetime);
                disp(ME.getReport);
            % Выключим логгирование
                diary off;

            fprintf('%% ----------------------------------------- %%\n\n');
            continue;
        end
    
        % Флаг моделирования
            isModeling.Value = false;
        % Лог
            fprintf('%s     Завершено.\n', datetime);
        % Выключим логгирование
            diary off;

        fprintf('%% ----------------------------------------- %%\n\n');
    end
end % Main

%% Подфункции
function [Objs, SimData] = MainChain(InObjs, Params)
% Главная функция, в которой выполняется моделирование

    % Присвоение объектов на выход и инициализация результата
        Objs = InObjs; clear InObjs;
        SimData = struct();

    % Поля структуры параметров
        pCommon = Params.Common;

    %% Прорисовка результатов
    if ~pCommon.isDraw, return; end

    % Список фигур и их имён
        f = cell(0);
        fNames = cell(0);

    if pCommon.isDraw > 1
        for k = 1 : length(f)
            saveas(f{k}, fullfile(pCommon.SaveDirName, fNames{k}), ...
                'fig');
        end
    end
    if pCommon.isDraw > 2
        for k = 1 : length(f)
            close(f{k});
        end
    end
end

function ProcessPaths(Paths, mode)
% Функция добавления и удаления путей модели

    mfolder = fileparts(mfilename("fullpath"));

    % Цикл по путям
    for k = 1 : length(Paths)

        % Добавление или удаление пути
        if isequal(mode, 'add')
            addpath(fullfile(mfolder, Paths{k}) );

        elseif isequal(mode, 'rm')
            rmpath(fullfile(mfolder, Paths{k}) );

        else
            error('Недопустимое значение параметра ''mode''.');
        end
    end
end

function ShutdownFun(Paths, isModeling)
% Функция вызывается при завершении работы главной функции

    % Если работа была прервана во время моделирования, сделаем запись в лог
    if isModeling.Value
        fprintf('%s     Не завершено.\n', datetime);
    end

    % Выключение логгирования
    diary off;

    % Удаление путей
    ProcessPaths(Paths.Value, 'rm');
end
