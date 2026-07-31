classdef HandleContainer < handle
% Вспомогательный класс для создания ссылок на хранимые значения

properties
    % Данные
        Value;
end

methods

    function obj = HandleContainer(Value)
    % Конструктор

        obj.Value = Value;
    end
end
end
