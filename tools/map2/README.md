# map2 : générateur de la map de Wrong Way Delivery

Étapes Luau lancées dans Roblox Studio (mode Edit) par le module `ServerStorage.MapLoader`,
qui télécharge `Lib`, `Plan`, `Build` et les étapes depuis ce dossier à un commit donné :

```lua
require(game.ServerStorage.MapLoader:Clone())("<sha>", { "00_Setup", "01_Terrain", ... }, 58)
```

| Étape | Contenu |
|---|---|
| 00_Setup | supprime l'ancienne map, crée l'arborescence `Workspace.Map`, éclairage cartoon |
| 01_Terrain | relief (montagnes, crête nord, colline, rivière, lac) écrit en voxels |
| 02_Roads | périphérique, boulevards, rues, carrefours, ronds-points, marquages, trottoirs, feux, panneaux, mobilier |
| 03_HQ | QG Wrong Way Delivery (bâtiment, entrepôt, cour camions, parking, parvis, spawn) |
| 04_Downtown | centre-ville : tours, place, Tour des Livreurs, parking à étages, parc |
| 05_Residential | quartier résidentiel (96 maisons) et parc |
| 06_Industrial | usine, port à conteneurs, logistique, parking camions |
| 07_Commercial | supermarché, station-service, restaurants, centre commercial, grande roue, cinéma… |
| 08_Hillside | route en spirale, maisons en terrasses, belvédère, escalier, rochers |
| 09_Outskirts | ponts, belvédère nord, cascade, ferme, motel, plage, phare, éoliennes, panneaux |
| 09t_Tunnel | tunnel du Col (à relancer après toute régénération du terrain, qui le rebouche) |
| 10_Nature | forêts et arbres hors ville, pins des collines, voitures-jouets dans les parkings |
| 11_Polish | finitions (vitrages variés, toit du parking, cours industrielles, lettres WRONG WAY) |
| 12_MeshyHouses | remplace les maisons du quartier résidentiel par 96 maisons Meshy AI (18 modèles importés dans ReplicatedStorage.Assets.Houses), avec jardins, clôtures, allées, boîtes aux lettres et arbres variés |
| HouseKit | module (pas une étape) : maisons construites en pièces à l'échelle Roblox, intérieurs (pièces, escaliers, portes intérieures), portes à charnière avec invite Ouvrir/Fermer gérées par ServerScriptService.HouseDoors ; 16 palettes naturelles, toits à 2 pans, à croupes, pignon en façade ou plat |
| 13_Houses | reconstruit le quartier résidentiel avec HouseKit : 8 types (classique, à étage, coloniale, ranch, ferme, villa, moderne, petite) ; workspace:SetAttribute("FurnishAll", true) meuble toutes les maisons (sinon seule la maison modèle) ; voitures Meshy dans les allées ; sauvegarde l'ancien quartier dans ServerStorage.Backups |
| 14_MeshyTrees | remplace tous les arbres de la carte par les 4 arbres Meshy AI (chêne, érable, bouleau, sapin) de ReplicatedStorage.Assets.City ; Lib.tree les utilise aussi pour les nouveaux arbres |
| 15_MeshyCars | remplace les voitures décoratives (ParkedCar, ParkedVan, ToyCar) par 5 voitures Meshy AI (berline, SUV, citadine, pick-up, monospace) de ReplicatedStorage.Assets.City ; Lib.meshyCar les pose aussi dans les allées des maisons (étape 13) ; les camions sont conservés |
| 16_HillHouses | remplace les maisons des collines (08) par des maisons HouseKit sur socles en pierre : plain-pied sur les pentes, à étage sur le plateau |
| 17_Fonts | applique les polices du jeu à tous les textes : Montserrat ExtraBold (enseignes, titres, lettres WRONG WAY) et Roboto Condensed Bold (panneaux routiers) ; Lib.label les utilise aussi |
| ShopKit | module : commerces visitables (vitrine, double porte vitrée, comptoir et caisse, gondoles, rayonnages, panneaux d'allées, réserve fermée par une porte) ; thèmes jouets, téléphones, vélos, cartons, laverie, épicerie et restaurant (salle, tableau-menu, cuisine professionnelle) |
| 18_Lighting | réglages Lighting : ambiance chaude, atmosphère légère, correction de couleur et bloom modérés |
| 19_Shops | remplace les 6 boutiques de la galerie marchande par des commerces ShopKit (anciens blocs dans ServerStorage.Backups) ; workspace:SetAttribute("ShopsOnly", "2") limite à certaines boutiques |

Coordonnées : X ouest → est, Z nord → sud, sol à y = 0, dessus de chaussée 0,2, trottoirs 0,8.
Aucun script de gameplay n'est créé : la map est uniquement du décor ancré.
| 22_MeshyHouse | Maison test MeshyAI (une seule, au bord de la ville) : modèle Meshy importé avec la porte peinte retirée du maillage, collisions invisibles, vraie porte, intérieur 5 pièces meublé. Nécessite `{"HouseKit","22_MeshyHouse"}`. |
