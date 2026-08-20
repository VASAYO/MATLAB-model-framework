function GenerateDefaultParams
% Функция выполняет генерацию сетап-листа с набором параметров по умолчанию
%
% Использование:
%   GenerateDefaultParams()

SetupListName = 'DefParams';

mpath = fileparts(mfilename("fullpath"));
addpath(fullfile(mpath, '..', 'Core'));
rmPathObj = onCleanup(@() rmpath(fullfile(mpath, '..', 'Core') ) );

Par = SetParams(struct, 1);

if exist(fullfile(mpath, [SetupListName '.m']), "file")
    delete(fullfile(mpath, [SetupListName '.m']));
end
Struct2SetupList(Par, SetupListName, mpath);
