function [Params, FNames] = SetParams(inParams, ParamsNumber)
% Функция дополнения набора параметров значениями по умолчанию и проверки
% значений, заданных пользователем

    % Пересохранение результата
    Params = inParams;

    % Имена полей структуры параметров
    FNames = { ...
        'Common' ...
        };

    % Цикл по полям
    for k = 1 : length(FNames)
        Field = FNames{k};

        % Если такого поля структуры нет, создадим его
        if ~isfield(Params, Field), Params.(Field) = []; end

        % Вызов функции заполнения данного поля структуры
        Fun = str2func(['SetParams' Field]);
        Params.(Field) = Fun(Params.(Field), ParamsNumber);
    end
end

%% Подфункции инициализации полей основной структуры
function Field = SetParamsCommon(inField, ParamsNumber)

    % Пересохранение результата
    Field = inField;

    % Папка для сохранения результата
    if ~isfield(Field, 'SaveDirName')
        Field.SaveDirName = 'Results';
    else
        % Проверка корректности введённого параметра
    end

    % Имя файла для сохранения результата и лога
    if ~isfield(Field, 'SaveFileName')
        Field.SaveFileName = sprintf('Results%d', ParamsNumber);
    else
        % Проверка корректности введённого параметра
    end

    % Нужно ли рисовать и сохранять рисунки:
    % 0 - нет; 1 - рисовать; 2 - рисовать и сохранить; 
    % 3 - рисовать, сохранить и закрыть.
    if ~isfield(Field, 'isDraw')
        Field.isDraw = 0;
    else
        % Проверка корректности введённого параметра
    end
end

%% Шаблон функции инициализации поля верхнего уровня
% function Field = SetParams<FName>(inField, ParamsNumber)
% 
%     % Пересохранение результата
%         Field = inField;
% 
%     % 
        % if ~isfield(Field, '')
        %     Field. = 
        % else
        %     % Проверка корректности введённого параметра
        % end
% end
