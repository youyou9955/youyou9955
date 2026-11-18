# Wrong Way Delivery

Jeu Roblox : tu livres des cartons en camionnette… à contresens. La camionnette a un plateau ouvert et les cartons à l'arrière ne sont pas attachés : ils glissent dans les virages et sautent sur les bosses.

## Structure (Rojo)

```
default.project.json            mapping Rojo -> Roblox Studio
rokit.toml                      version de Rojo
src/shared/   -> ReplicatedStorage.Shared
  Config.luau                   tous les réglages (vitesse, adhérence, suspension, cartons)
  VanPhysics.luau               physique arcade + cartons instables (script principal)
src/server/   -> ServerScriptService.Server
  VanServer.server.luau         construit la camionnette, charge les cartons, propriété réseau, cartons perdus
src/client/   -> StarterPlayer.StarterPlayerScripts.Client
  VanClient.client.luau         conduite côté joueur + HUD (vitesse, cartons restants)
assets/                         exports des modèles 3D (.fbx/.obj) si besoin
```

Les modèles 3D (générés avec Meshy AI, fichiers .glb dans `Documents\WrongWayDelivery\models`) vont dans `ReplicatedStorage.Assets` (dans Studio) : `Van`, `Car`, `Truck`, `Box`.
S'ils sont présents, le serveur les colle comme visuels sur les pièces de collision ; sinon il utilise des blocs simples.

## Commandes

| Touche | Action |
| --- | --- |
| Z / W | accélérer |
| S | freiner / marche arrière |
| Q / A, D | tourner |
| Shift gauche (X manette) | frein à main / drift |
| R (Y manette) | remettre sur les roues et recharger les cartons |

## Comment ça marche

- **Suspension raycast** : 4 rayons sous le châssis, ressorts auto-réglés selon la masse.
- **Conduite arcade** : la vitesse avant et l'adhérence latérale sont pilotées directement (pas de roues physiques), le braquage contrôle la vitesse de rotation.
- **Cartons instables** : des pièces libres avec frottement réglable. On exagère l'inertie quand la camionnette accélère ou tourne, et on les fait sauter sur les bosses. Un carton qui sort du plateau est compté perdu.
- **Réseau** : le conducteur possède la physique (client) ; le serveur la reprend quand personne ne conduit.

## Lancer avec Rojo

```
rokit install
rojo serve
```
Puis dans Studio : plugin Rojo -> Connect.

## La ville (map)

Générée par les scripts `tools/city/*.luau` (à exécuter dans Studio, dans l'ordre 01 → 13 ; `01_Setup` efface et reconstruit tout).

- `10_Meshy` et `12_MeshyMore` remplacent les blocs par les modèles Meshy AI rangés dans `ReplicatedStorage.Assets.City` (maisons A à E, maison de ville, tours Office/OfficeB/OfficeC, boutiques Shop/ShopB/ShopC, entrepôt, arbres, palmier, lampadaire, banc, poubelle, bouche d'incendie, boîte aux lettres, buisson, jardinière, vache, abri de bus, socle de panneau, conteneur). Fichiers .glb dans `Documents\WrongWayDelivery\models\city` et `city2`.
- `11_Signs` donne aux panneaux l'aspect de la vraie signalisation (liseré, police routière, dos en aluminium, poteaux galvanisés, vrais STOP octogonaux).
- `13_Houses` reconstruit chaque maison pour qu'on puisse y entrer : porte qui s'ouvre (touche E, script `src/server/HouseDoors.server.luau`), pièces, fenêtres, escalier et étage, plafonnier, meubles Meshy (`models\furniture`). Chaque maison a son style (façade, toit, couleurs, volets, porche, garage).
- `14_Realistic` passe « réaliste » : éclairage naturel (ombres nettes, couleurs moins saturées, atmosphère) et remplacement des arbres, sapins, buissons, tours et boutiques par une série Meshy réaliste avec textures PBR (`models\city3`, suffixe `R` dans `Assets.City`). Les maisons (13) prennent aussi les buissons réalistes, l'enduit intérieur et des rideaux.
Tout est rangé dans `Workspace.Map` : `Roads/` (MainRoads, SecondaryRoads, Intersections, Sidewalks, RoadMarkings, Bridges, Signs), `Districts/` (Downtown, Residential, Industrial, Commercial, Hillside, Outskirts), `Headquarters`, `Landmarks`, `Vegetation`, `StreetFurniture`, `LightingObjects`, `DeliveryZones` (repères tagués `DeliveryZone`), `Spawns`.

- Grille de 6 x 6 îlots (axes tous les 160 studs), avenues de 44 studs, rond-point central, 48 carrefours avec feux ou STOP.
- QG Wrong Way Delivery à l'îlot nord-est du rond-point ; la camionnette apparaît devant, sur l'avenue.
- Rivière à l'est avec un pont haubané et deux ponts bas, lac avec plage, collines au sud (route en spirale, belvédère, tunnel), périphérique extérieur, montagnes en bordure.
