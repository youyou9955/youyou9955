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
