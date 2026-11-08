local W=Wayfinder
W.DataVersion=2
-- Context/transition hints only. Quest actions use the active Forever database.
W.Zones={
 [1438]={name="Teldrassil",region="Kalimdor",min=1,max=12,next={1439},hint="Follow the paths between Shadowglen, Dolanaar and the outlying settlements. For caves, find the entrance; the arrow points to the objective area."},
 [1439]={name="Darkshore",region="Kalimdor",min=10,max=20,next={1440},hint="Use Auberdine as your return hub. Combine quests along the coast before returning."},
 [1440]={name="Ashenvale",region="Kalimdor",min=18,max=30,next={1442,1443},hint="Use Astranaar and the roads to connect quest areas. Watch for higher-level enemies away from the road."},
 [1442]={name="Stonetalon Mountains",region="Kalimdor",min=20,max=30,next={1443}},
 [1443]={name="Desolace",region="Kalimdor",min=30,max=40,next={1444}},
 [1444]={name="Feralas",region="Kalimdor",min=40,max=50,next={1446,1448}},
 [1446]={name="Tanaris",region="Kalimdor",min=40,max=50,next={1449}},
 [1447]={name="Azshara",region="Kalimdor",min=45,max=55,next={1452}},
 [1448]={name="Felwood",region="Kalimdor",min=48,max=55,next={1452}},
 [1449]={name="Un'Goro Crater",region="Kalimdor",min=50,max=55,next={1451}},
 [1451]={name="Silithus",region="Kalimdor",min=55,max=60,next={1452}},
 [1452]={name="Winterspring",region="Kalimdor",min=55,max=60,next={1451}},
 [1426]={name="Dun Morogh",region="Eastern Kingdoms",min=1,max=12,next={1432}},
 [1429]={name="Elwynn Forest",region="Eastern Kingdoms",min=1,max=12,next={1436,1433}},
 [1432]={name="Loch Modan",region="Eastern Kingdoms",min=10,max=20,next={1437,1433}},
 [1436]={name="Westfall",region="Eastern Kingdoms",min=10,max=20,next={1433,1431}},
 [1433]={name="Redridge Mountains",region="Eastern Kingdoms",min=15,max=25,next={1431,1437}},
 [1431]={name="Duskwood",region="Eastern Kingdoms",min=18,max=30,next={1437,1434},hint="Darkshire is the eastern hub. Gather nearby pickups before going west, and combine objectives around the same farm or cemetery. Use the main road across the zone."},
 [1437]={name="Wetlands",region="Eastern Kingdoms",min=20,max=30,next={1417,1434}},
 [1417]={name="Arathi Highlands",region="Eastern Kingdoms",min=30,max=40,next={1425,1418}},
 [1424]={name="Hillsbrad Foothills",region="Eastern Kingdoms",min=20,max=30,next={1417}},
 [1434]={name="Stranglethorn Vale",region="Eastern Kingdoms",min=30,max=45,next={1418,1425}},
 [1418]={name="Badlands",region="Eastern Kingdoms",min=35,max=45,next={1427}},
 [1425]={name="The Hinterlands",region="Eastern Kingdoms",min=40,max=50,next={1427,1422}},
 [1435]={name="Swamp of Sorrows",region="Eastern Kingdoms",min=35,max=45,next={1419}},
 [1419]={name="Blasted Lands",region="Eastern Kingdoms",min=45,max=55,next={1428}},
 [1427]={name="Searing Gorge",region="Eastern Kingdoms",min=45,max=50,next={1428}},
 [1428]={name="Burning Steppes",region="Eastern Kingdoms",min=50,max=58,next={1422}},
 [1422]={name="Western Plaguelands",region="Eastern Kingdoms",min=50,max=58,next={1423}},
 [1423]={name="Eastern Plaguelands",region="Eastern Kingdoms",min=55,max=60,next={1422}},
}
W.ClassMasks={WARRIOR=1,PALADIN=2,HUNTER=4,ROGUE=8,PRIEST=16,DEATHKNIGHT=32,SHAMAN=64,MAGE=128,WARLOCK=256,MONK=512,DRUID=1024}
W.ClassicRaceMasks={[1]=1,[2]=2,[3]=4,[4]=8,[5]=16,[6]=32,[7]=64,[8]=128,[10]=512,[11]=1024}
W.ActionLabels={grind="GRIND",pickup="ACCEPT",objective="QUEST",turnin="TURN IN",deliver="SPEAK",item="USE ITEM",travel="TRAVEL",wait="ROUTE STATUS"}
