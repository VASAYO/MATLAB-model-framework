function Struct2SetupList(S, Filename, FilePath)
% Генерация сетап-листа на основе структуры параметров
% 
% Использование:
%   Struct2SetupList(S) - 
%       функция анализирует структуру S и генерирует код для формирования
%       сетап-листа, после чего записывает его в файл Setup.m, находящийся
%       в том же каталоге, что и функция. Если Setup.m не существует, то он
%       создаётся.
% 
%   Struct2SetupList(S, Filename) - 
%       функция сохраняет код в файл с именем [Filename '.m'], находящийся
%       в той же директории, что и функция. Если файл существует, то он
%       создаётся.
%
%   Struct2SetupList(S, Filename, FilePath) - 
%       функция сохраняет код в файл с именем [Filename '.m'], находящийся
%       в директории Filepath. Если файл существует, то он создаётся.
% 
% Параметры:
%   S - 
%       struct
%       структура параметров.
%
%   Filename - 
%       'Setup' (default) | character vector | string scalar
%       имя файла для сохранения кода.
%
%   FilePath - 
%       ['.' filesep] (default) | character vector | string scalar
%       каталог файла для сохранения кода.

%% Входные аргументы
arguments
    S struct;
    Filename char = 'Setup';
    FilePath char = ['.' filesep];
end

%% Анализ структуры
Tree = RecursiveStructAnalyzer(S);

% Если структура оказалась пустой, ничего не записываем
    if isempty(Tree), return; end

%% Запись результата в файл
% Полное имя сетап-листа
    SetupListPath = fullfile(FilePath, Filename);
    if ~strcmp(SetupListPath(end-1:end), '.m')
        SetupListPath = [SetupListPath '.m'];
    end

% Откроем/создадим сетап-файл
    if exist(SetupListPath, "file")
        fid = fopen(SetupListPath, "a");
    else
        if ~exist(FilePath, "dir")
            mkdir(FilePath);
        end
        fid = fopen(SetupListPath, "w");
    end

% Проверка корректности
    if fid < 0
        error('Не удалось открыть/создать файл: %s', SetupListPath);
    else 
        fcloseObj = onCleanup(@() fclose(fid) );
    end

% Вставка заголовка сетап-листа
    header = [newline '% ----------------------------------------------------------------------- %' newline ...
        '% This is an automatically generated setup-list.' newline ...
        '% Generation date: ' char(datetime) newline];
    fwrite(fid, header);

% Формирование сетап-листа
PrevOldestField = Tree(1).Fields{1};
for k = 1 : length(Tree)
    
    % Формируем очередную строку сетап-листа
        str = '';
        for ifil = 1 : length(Tree(k).Fields)
            str = [str Tree(k).Fields{ifil} '.']; %#ok<AGROW>
        end
        str = str(1 : end-1);
        strData = Tree(k).Data;
        if ischar(strData)
            strData = ['''' strData '''']; %#ok<AGROW>

        elseif isnumeric(strData) || islogical(strData)
            strData = Matrix2StrConversionHelper(strData);
        end
        str = [str ' = ' strData ';' newline]; %#ok<AGROW>

        % Оставляем пустую строку между строками инициализации разных полей
        % верхнего уровня структуры
            if ~isequal(Tree(k).Fields{1}, PrevOldestField)
                str = [newline str]; %#ok<AGROW>
                PrevOldestField = Tree(k).Fields{1};
            end

    % Пишем строку
        fwrite(fid, str);
end

% Заканчиваем ключевым словом
    fwrite(fid, ['% End of Params' newline]);

end % function Struct2SetupList

%% Подфункции
function Tree = RecursiveStructAnalyzer(S, inTree, OlderFields)
% Функция рекурсивного анализа структуры S. Результатом работы является
% массив структур Tree.
%
% Каждый элемент Tree - структура, содержащая следующие поля:
%   Fields - cell-массив, содержащий последовательность полей S, по которым
%            находится соответствующий элемент;
%   Data   - значение поля с данными;
% 
% Пример использования:
%   Tree = RecursiveStructAnalyzer(S);

    % Обработка входных аргументов
        if exist('inTree', "var") && ~isempty(inTree)
            Tree = inTree;

        else
            Tree = struct( ...
                'Fields', {}, ...
                'Data',   [] ...
                );
        end
        if ~exist('OlderFields', "var"), OlderFields = {}; end

    % Имена полей S
        FNames = fieldnames(S);

    % Цикл по полям S
    for k = 1 : length(FNames)

        % Если поле не является подструктурой, дополняем Tree
        if ~isstruct(S.(FNames{k}) )
            bufstruct = struct( ...
                'Fields', [], ...
                'Data',   [] ...
                );
            buffields = OlderFields;
            buffields{end+1} = FNames{k}; %#ok<AGROW>
            bufstruct.Fields = buffields;
            bufstruct.Data = S.(FNames{k});

            Tree(end+1) = bufstruct; %#ok<AGROW>

        % Иначе рекурсивно вызываем функцию
        else
            Tree = RecursiveStructAnalyzer(S.(FNames{k}), Tree, [OlderFields, FNames(k)]);
        end
    end
end

function str = Matrix2StrConversionHelper(A)

    % Вычислим размер матрицы А
        DimSizes = size(A);

    % Если A - пустое значение
        if isequal(DimSizes, [0 0])
            str = '[]';
            return;

        elseif any(DimSizes == 0)
            str = ['zeros([' num2str(DimSizes) ']'];
            str = DeleteDoubleSpaces(str);
            return;
        end

    % Если A - матрица с тремя и более измерениями, сформируем строку при
    % помощи reshape
    if length(DimSizes) > 2
        strA = ['[' num2str(A(:).') ']'];
        strDimSizes = ['[' num2str(DimSizes) ']'];
        % Удалим лишние пробелы
            strA        = DeleteDoubleSpaces(strA);
            strDimSizes = DeleteDoubleSpaces(strDimSizes);

        str = ['reshape(' strA ', ' strDimSizes ')'];
        return;
    end

    % Если A - скаляр
    if isequal(DimSizes, [1 1])
        str = num2str(A);
        return;
    end

    % Если A - вектор-строка
    if DimSizes(1) == 1 && DimSizes(2) > 1
        str = ['[' num2str(A) ']'];
        str = DeleteDoubleSpaces(str);
        return;
    end

    % Если A - вектор-столбец
    if DimSizes(1) > 1 && DimSizes(2) == 1
        str = ['[' num2str(A.') '].'''];
        str = DeleteDoubleSpaces(str);
        return;
    end

    % Если A - двумерная матрица
        str = num2str(A);
        str = [str, repmat('; ', DimSizes(1), 1)];
        str = str.';
        str = str(:).';
        str = DeleteDoubleSpaces(str);
        % Удалим ; в конце и пробелы в начале
            str = str(1:end-2);
            if strcmp(str(1), ' '), str = str(2:end); end
        str = ['[' str ']'];

end

function Str = DeleteDoubleSpaces(inStr)
    Str = inStr;
    while contains(Str, '  '), Str = strrep(Str, '  ', ' '); end
end
