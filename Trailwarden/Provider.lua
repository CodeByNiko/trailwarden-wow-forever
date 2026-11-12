local W=Trailwarden
W.ProviderGeneration=0;W.ProviderReads={};W.ProviderReadCacheHits=0
local current,signature;local hooked=setmetatable({},{__mode='k'})
function W.InvalidateProviderData(reason,structural)
    W.ProviderGeneration=W.ProviderGeneration+1
    if W.CancelPlanning then W.CancelPlanning() end
    W.ProviderChangeReason=reason;W.ProviderRebuildNeeded=true
    if structural then W.ProviderIndexDirty=true end
    if W.InvalidateDataCaches then W.InvalidateDataCaches() end
end
local function hook(owner,key,callback)
    if type(owner)~='table' or type(owner[key])~='function' or type(hooksecurefunc)~='function' then return end
    hooked[owner]=hooked[owner] or {};if hooked[owner][key] then return end
    hooksecurefunc(owner,key,callback);hooked[owner][key]=true
end
function W.EnsureProvider()
    local p=LibQuestieDB;local identity=W.ProviderIdentity()
    local stamp=table.concat({identity.version,tostring(identity.contract),identity.build,identity.mode or "unknown",identity.flavor or "unknown",identity.locale or "enUS"},':')
    if p~=current or stamp~=signature then
        local prior=current;current=p;signature=stamp
        if prior then W.ProviderIndexDirty=W.ProviderIndexDirty or p~=prior;W.InvalidateProviderData('provider identity changed',p~=prior) end
    end
    local ok,message=W.Call(p and p.RequireContract,3)
    W.ProviderCompatible=ok=='ok' and message==true
    if not W.ProviderCompatible then W.ProviderError='QuestieDB with supported consumer contract 3 is required. Update QuestieDB and restart WoW.';return false end
    W.ProviderError=nil
    local function changed() W.InvalidateProviderData('provider correction/invalidation',true) end
    hook(p,'InvalidateCache',changed);hook(p,'ApplyRegisteredCorrections',changed)
    local registry=p.Corrections
    for _,key in ipairs({'Set','ApplyRegisteredCorrections','UnregisterCorrection'}) do hook(registry,key,changed) end
    if p.l10n then
        hook(p.l10n,'SetLocale',function(locale) W.ProviderLocale=locale;W.InvalidateProviderData('provider locale changed',false) end)
        hook(p.l10n,'SetCorrection',function() W.InvalidateProviderData('provider translation changed',false) end)
    end
    W.ProviderHooksAvailable=type(hooksecurefunc)=='function'
    return true
end
function W.GetProviderCatalog(ids)
    local index=W.ProviderCatalogIndex;local p=LibQuestieDB;local info=W.ProviderIdentity()
    if not index or index.schema~=1 or W.ProviderIndexDirty or not W.ProviderHooksAvailable or type(p.GetProvenance)~='function' then W.CatalogIndexStatus='bounded runtime fallback';return end
    for _,key in ipairs({'version','contract','build','mode','flavor'}) do if index[key]~=info[key] then W.CatalogIndexStatus='provider mismatch; bounded runtime fallback';return end end
    if #ids~=#index.ids then W.CatalogIndexStatus='quest membership changed; runtime fallback';return end
    for i,id in ipairs(ids) do
        if id~=index.ids[i] or p.GetProvenance('Quest',id,'startedBy')~='QuestieDB' then W.CatalogIndexStatus='corrected quest relations; runtime fallback';return end
    end
    for kind,list in pairs(index.entities) do for _,id in ipairs(list) do
        if p.GetProvenance(kind,id,'spawns')~='QuestieDB' then W.CatalogIndexStatus='corrected starter coordinates; runtime fallback';return end
    end end
    W.CatalogIndexStatus='verified offline zone index';return index
end
