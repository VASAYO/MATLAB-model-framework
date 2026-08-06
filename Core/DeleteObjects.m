function DeleteObjects(Objs)
% Удаление объектов

ObjNames = fieldnames(Objs);
for k = 1 : length(ObjNames)
    Obj = Objs.(ObjNames{k});
    delete(Obj);
end
