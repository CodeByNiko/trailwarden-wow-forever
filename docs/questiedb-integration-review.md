# QuestieDB: konkret læring for Trailwarden

Analyse: 12. november 2026. Dette er en kildekodeanalyse og implementeringsplan; ingen runtimeændringer eller dependency-opgradering er udført som del af analysen.

## Grundlag og afgrænsning

- QuestieDB er undersøgt ved commit `90ab55bdddd6ef6507fe51610b9c26948bbeb637`, hvis Source-TOC angiver version 1.1.0. Trailwardens CI er fortsat bundet til release `v1.0.14` og dens SHA-256.
- `src/read/shared.lua` og `src/read/baked.lua` er også hentet ved `v1.0.14`: deres indhold er identisk med de gennemgåede filer ved ovenstående commit. De centrale observationer om tabelkopier og cache gælder derfor også vores nuværende testversion.
- Trailwarden er undersøgt ved feedback-branchens commit `8271e75f1b7fee1337e61b412cb07e85a52fb51a`.
- QuestieDB er dataleverandøren. Questies tilgængelighedspolitik, tracker og map-/event-håndtering er ikke det samme projekt. Denne gennemgang dokumenterer ikke hele Questies UI-arkitektur.
- QuestieDBs performance-dokument indeholder både historiske forsøg og senere produktionsvalg. Afsnit 9.12 erstatter tidligere læserdesign; tallene er målt på Classic Era og kan ikke overføres direkte til Forever eller vores live CPU-procenter.

## Vigtigste konklusion

Den største læring er at begrænse, hvilke data forbrugeren overhovedet rører, hvor ofte den læser dem, og hvor længe den beholder resultaterne. QuestieDBs interne cache gør skalarlæsninger billige, men en tabel-læsning producerer stadig en ny tabel til hvert kald. Trailwarden kan derfor skabe omfattende allokeringer oven på en varm provider.

Vores seneste rettelse fjerner den globale cache af udvidede world-points og begrænser lokal retention. Den globale katalogbygger læser imidlertid stadig `spawns` for alle quest-startere. Det varmer providerens cache og dekoder midlertidige tabeller. Den tilbageværende opstartsomkostning er ikke løst alene ved at gemme zone-id'er frem for positioner.

## Fund og prioritering

| Prioritet | Verificeret mønster i QuestieDB | Betydning og næste ændring for Trailwarden |
| --- | --- | --- |
| P0 | Baked-mode cacher scalar rows og tabel-producers ved første brug. Hver tabel-producer dekoder en frisk tabel. | Reducer globale `spawns`-læsninger. Instrumentér antal provider-kald pr. felt og plan, før yderligere cache tilføjes. Vores `starterMaps` i Database.lua læser stadig globale spawn-data. |
| P0 | Returnerede entity-tabeller er ejet af kalderen og allerede dybt uafhængige. | Undgå at klone dem igen uden et konkret ejerskabsbehov. `RecordFact` laver aktuelt en ny dyb kopi ved hvert registreret felt, også ved gentagne cache-hits i samme plan. Gør capture begrænset og undgå gentaget kopiering af uændrede facts; sikker isolation skal bevares. |
| P0 | Den virkelige provider returnerer nye tabeltræer for gentagne læsninger. | Performance-fixturen skal returnere friske spawn-kopier. Den nuværende fixture deler `coords` mellem læsninger. Dens 500-quest-måling beskytter vores egen retention, men omfatter ikke providerens decode/producer-cache eller korrekte allokeringsadfærd. |
| P1 | Cache-nøgler adskiller entity, felt og datalag. Manglende felter caches med en sentinel. | Indfør eventuelt en begrænset cache for identiske interne læsninger inden for én planner-pass. Behandl dens værdier som immutable internt, og kopier ved mutation. Cache ikke fejl som permanente tomme resultater. Vores Q-cache skelner allerede loaded/nil fra ikke læst. |
| P1 | Corrections invaliderer berørte datatyper; navneindekset overlever ændringer, som ikke påvirker navne eller medlemskab. | Giv vores egne caches eksplicit generation/livscyklus for provider, flavor, locale og kendte dataændringer. Vores Q-cache og afledte katalog kan ellers forblive gamle efter runtime Corrections. Den dokumenterede API giver ikke et generelt consumer-change-callback, der alene løser dette. |
| P1 | Asynkron navneindeksering publicerer først et færdigt indeks og genstarter ved ændret revision. Kalderen ejer coroutine og scheduler. | Bevar den nuværende atomiske katalog-publicering. Brug samme generationskontrol ved fremtidig opdeling af den dyre ruteplanlægning over frames. En løkke skal kunne afbrydes; en enkelt native decode kan ikke preemptes. |
| P1 | `RequireContract` kontrollerer et understøttet interval, uafhængigt af versionsnavnet. | Lav en tydelig preflight med brugerrettet fejl, før afhængige features bruges. Den nuværende kontrakt-3-kontrol i Tracking.lua bruges til race masks, men er ikke en samlet integrationsgate. Kontrakt 4 er kun nødvendig, hvis vi anvender de nye class/npc-flagtabeller. |
| P1 | Source og Baked har samme værdikontrakt, men forskellig materialisering. Source kan materialisere en hel entity-type ved første adgang; Baked starter med ID-headere og dekoder derefter per entity/felt. | Log provider-mode, flavor og version i diagnosticeringen. Benchmark den faktiske Forever-release, ikke alene en Source-checkout eller stub. En kold læsning kan koste mere end senere identiske læsninger. |
| P2 | Named getters springer feltets navneopslag over. `GetAll` kalder stadig feltlæseren for hvert ønsket felt og returnerer en packed tabel med `n`. | Optimer først antal læsninger og kopier. Brug named getters på målte hot paths, hvis public API findes, med kompatibel fallback. `GetAll` er ikke automatisk en performance-genvej. |
| P2 | Navneindekset bygges lazily over alle navne og kan bygges asynkront. `GetRaw` omgår Corrections/locale og er ukachet. | Bevar ID-baseret arbejde og små lokale navneopslag, når vi allerede kender ID'erne. Undgå globale navneindekser i hover-/map-events. Bevar almindelige getters til spillervisning; brug ikke GetRaw som en hastighedsgenvej. |

## Konkret implementeringsrækkefølge

### 1. Gør målingerne repræsentative

Udvid performance-fixturen til korrekt fresh-copy-ejerskab. Tilføj tællere for provider-kald pr. datatype/felt og allokering pr. planner-pass i et kontrolleret testmiljø. Udvid den eksisterende integration med den officielle, checksum-verificerede Forever-ZIP til gentagne cold/warm workloads med aktive quests, map-storm, en tæt befolket zone og en længere session.

Mål separat: tidsforbrug, midlertidigt allokeret heap og beholdt heap efter collection. Runtime skal ikke tvinge garbage collection for at frembringe et pænt tal. Addon-attribution og hele klientens heap er forskellige målinger. Oplys provider-mode, version, build, locale og profiling-opsætning sammen med resultaterne.

### 2. Fjern overflødigt integrationsarbejde

Prototype en planner-pass-cache for gentagne interne tabel-/skalarlæsninger og en begrænset diagnostic-capture. Dokumentér, hvilke værdier må muteres, og hvor en kopi er nødvendig. Bevar de eksisterende budgetter for points og replay.

Acceptance: samme rute/queue, færre gentagne `spawns`/objectives/drop-læsninger og færre kopier; fejl og ændrede objective counts skal stadig håndteres straks. To forskellige planner-passes må ikke dele en utilsigtet mutable tabel. Fejl må kunne genprøves.

### 3. Fjern den globale spawn-pass fra normal opstart

Undersøg et lille afledt quest-starter/zone-indeks frem for at dekode globale spawns i alle sessioner. Mulighederne er et upstream-understøttet indeks eller et verificeret, versionsbundet offline-indeks. Et lokalt afledt indeks kræver også en defineret refresh- og invalidationsstrategi.

Det skal håndtere den konkrete Forever-provider, data-Corrections, tilføjede/tilbagetrukne quests og ændrede koordinater. Questens zone-/sorteringsfelt eller en NPC's dominerende zone må ikke ukritisk bruges som erstatning for alle faktiske starter-zoner. Ved mismatch skal fallback være eksplicit og bevare accepterede quests og live questgiver-observationer. Eventuel distribution af afledte provider-data kræver særskilt vurdering af datagrundlag og licens.

### 4. Styrk livscyklus og kompatibilitet

Definér én integrationsgate og egne cache-generationer. Test ændret provider, aktiv locale og runtime Correction efter en varm lokal cache. QuestieDBs rod-InvalidateCache er ikke en tilstrækkelig ændringsnotifikation: Correction-publicering går direkte gennem entity.SetOverlay. Undgå derfor at love korrekt invalidation ud fra et hook på den ene funktion.

Vi bør heller ikke rydde QuestieDBs globale caches ved map-skift eller som generel hukommelsesoprydning; det rammer andre consumers og kan udløse ny cold decode. Hvis der mangler en stabil public change-notifikation, er en upstream API-forespørgsel og en dokumenteret manuel rebuild-fallback sikrere end afhængighed af interne tabeller.

## Det vi allerede har på plads

- Hård QuestieDB-afhængighed, checksum-pinnet integration og korrekt read-only behandling af ID-listen.
- Egne afledte points frem for kopiering af hele providerens rå database.
- Atomisk katalog-publicering, generationskontrol, pause ved combat/map og et budget mellem katalog-items.
- Bounded point-cache/replay, isolerede planner-inputs og lokale timing-/eventtællere på feedback-branchen.
- Almindelige offentlige getters frem for GetRaw i normal routing.

De punkter er gode fundamenter; de beviser ikke, at den rapporterede live CPU-spids eller hukommelsesvækst er elimineret.

## Afgrænsninger og faldgruber

Support-data har en anden kontrakt end entity-getters: `Support.Get` returnerer de delte reference-moduler. Vores map-lookup-kode laver en kopi, før den merger overrides. Den kopi bør ikke fjernes med argumentet om, at entity-getters allerede kopierer.

Historiske performance-afsnit diskuterer en teoretisk shared-table-variant. Den er ikke den public API, Trailwarden kan antage. Genbrug af en immutable værdi i vores egen korte beregning er noget andet end at ændre providerens værdier eller dele dem på tværs af consumers.

QuestieDBs LICENSE.md beskriver en blandet historisk licenssituation og GPLv3-vilkår for dele af projektet; Trailwarden er MIT. Analysen bruger mønstre og offentlig API-dokumentation og indfører ingen kopierede QuestieDB-implementeringer. Konkret kopiering eller distribution af kildefiler/data kræver særskilt afklaring.

### Verificering udført i denne analyse

Dokumentation og implementering er læst via GitHub. De relevante read-filer er sammenlignet med `v1.0.14`; Trailwardens konkrete kald og test-fixture er gennemgået lokalt. Der er ikke udført nye live WoW-målinger, installeret/opgraderet QuestieDB eller kørt den rigtige provider lokalt i denne analyse. De nødvendige Python-emuleringsafhængigheder er ikke installeret i dette miljø. Der er ikke ændret runtimekode eller oprettet PR.

## Primære kilder

Alle QuestieDB-links nedenfor er bundet til det undersøgte commit, så en senere master-ændring ikke ændrer analysegrundlaget.

1. [Consumer API og ejerskab](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/docs/api.md#value-ownership)
2. [Den fælles read-path og tabel-producers](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/read/shared.lua#L267)
3. [Baked backend: IDs, scalar rows og CBOR-producers](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/read/baked.lua#L55)
4. [Source-mode materialisering](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/read/source.lua#L94)
5. [Asynkron og revisionsbeskyttet navneindeksering](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/read/shared.lua#L466)
6. [Selektiv Correction-publicering](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/corrections/registry.lua#L521)
7. [Kontraktkontrol og eksplicit invalidation](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/api.lua#L80)
8. [Delte support-data](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/src/support/data.lua)
9. [Performance-målinger og nyere produktionsbeslutning](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/docs/read-performance.md#912-cbor-row-acceptance-2026-09-03)
10. [Licensgrundlag](https://github.com/Questie/QuestieDB/blob/90ab55bdddd6ef6507fe51610b9c26948bbeb637/LICENSE.md)
11. [Pinned API: v1.0.14](https://github.com/Questie/QuestieDB/blob/v1.0.14/docs/api.md)
12. [Trailwardens globale spawn-læsning og diagnostic-kopiering](https://github.com/CodeByNiko/trailwarden-wow-forever/blob/8271e75f1b7fee1337e61b412cb07e85a52fb51a/Trailwarden/Database.lua)
13. [Trailwardens syntetiske performance-fixture](https://github.com/CodeByNiko/trailwarden-wow-forever/blob/8271e75f1b7fee1337e61b412cb07e85a52fb51a/tests/performance.lua)
