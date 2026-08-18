# CC RaidTools Reforged

Addon World of Warcraft Retail 12.1, sans dépendance externe, destiné à faciliter la gestion d’un raid sans compromettre les actions protégées.

## Fonctions

- promotions automatiques par joueur, avec validation du leadership et du combat ;
- invitations sur mots-clés, avec filtre optionnel réservé à la guilde ;
- journal de combat automatique par difficulté, sans arrêter un journal lancé manuellement ;
- tableau Ready Check événementiel avec consommables et buffs de raid ;
- barre sécurisée de marques de cible et marqueurs au sol ;
- raccourci sécurisé pour placer le focus sur l’unité sous la souris ;
- migration automatique des réglages de l’ancien `CC_RaidTools` ;
- interface modulaire sombre et cohérente avec l’identité CC RaidTools, accessible avec `/ccrt` ;
- tableau Ready Check visuel avec états colorés, icônes et repères de classe.

Les textures de l’interface sont embarquées dans `TexturesGUI/`. Leur chemin est construit à partir du nom réel du dossier de l’addon, afin que l’interface reste fonctionnelle si le dossier est renommé.

## Installation

Copier le dossier dans `_retail_/Interface/AddOns/`, puis lancer `/reload`. Ouvrir la configuration avec `/ccrt`.

## Tests conseillés

Tester `/reload`, l’ouverture et le déplacement de `/ccrt`, chaque onglet et état de contrôle, l’entrée et la sortie de combat, un Ready Check réel, les changements de zone, un donjon/raid configuré pour AutoLog, ainsi que les marqueurs en et hors combat.
