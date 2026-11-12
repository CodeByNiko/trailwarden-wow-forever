local W=Trailwarden

-- This catalog covers Trailwarden's own controls and map cues only. Quest names,
-- provider text, and world names remain owned by the game and QuestieDB.
W.LocaleCatalogs={
    enUS={
        action_escort="ESCORT",action_grind="GRIND",action_pickup="ACCEPT",action_objective="QUEST",
        action_turnin="TURN IN",action_deliver="SPEAK",action_item="USE ITEM",action_travel="TRAVEL",action_wait="ROUTE STATUS",
        marker_entrance="E",marker_objective="Q",marker_entrance_name="Cave",marker_entrance_suffix="entrance",
        marker_objective_name="Quest objective",marker_not_path="Not a walking path",
        marker_help="Markers use letters as well as colors: E is an entrance; Q is an objective.",
        marker_path_warning="A marker is an access point or destination, not a verified walking line.",
        language_changed="Language set to English.",language_usage="Language: /tw language auto, en, or da.",
    },
    daDK={
        action_escort="ESKORTE",action_grind="KAMP",action_pickup="ACCEPTÉR",action_objective="OPGAVE",
        action_turnin="AFLEVER",action_deliver="TAL",action_item="BRUG GENSTAND",action_travel="REJSE",action_wait="RUTESTATUS",
        marker_entrance="I",marker_objective="O",marker_entrance_name="Hule",marker_entrance_suffix="indgang",
        marker_objective_name="Opgavemål",marker_not_path="Ingen gangrute",
        marker_help="Markører bruger både bogstaver og farver: I er en indgang; O er et mål.",
        marker_path_warning="En markør er et adgangspunkt eller mål, ikke en bekræftet gangrute.",
        language_changed="Sproget er sat til dansk.",language_usage="Sprog: /tw language auto, en eller da.",
    },
}

local function language()
    local selected=W.GetProfile and W.GetProfile().language or "auto"
    if selected=="da" then return "daDK" end
    if selected=="en" then return "enUS" end
    local current=W.Safe(GetLocale)
    return current=="daDK" and "daDK" or "enUS"
end

function W.L(key)
    local english=W.LocaleCatalogs.enUS
    local selected=W.LocaleCatalogs[language()]
    return (selected and selected[key]) or english[key] or key
end
