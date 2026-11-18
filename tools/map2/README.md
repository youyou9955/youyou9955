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

Coordonnées : X ouest → est, Z nord → sud, sol à y = 0, dessus de chaussée 0,2, trottoirs 0,8.
Aucun script de gameplay n'est créé : la map est uniquement du décor ancré.
