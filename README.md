# PF_Haskell

Projet de programmation fonctionnel en Haskell sur la compression de fichiers.

## Compilation et Exécution

Pour compiler et exécuter le projet :

```bash
cabal build Main.hs
cabal run Main.hs
```

## Bibliothèques Utilisées

- **Data.Map** : Utilisée dans le module Huffman pour créer une correspondance efficace entre caractères et leurs codes binaires
- **Data.List** : Utilisée pour les opérations de tri dans la transformée de Burrows-Wheeler
- **System.FilePath** : Pour la manipulation des chemins de fichiers (lecture/écriture)

## Fonctionnalités Implémentées

### Fonctionnalités de Base

✅ **Codage de Huffman** : Compression et décompression complètes avec construction d'arbre de codes
✅ **Transformée de Burrows-Wheeler (BWT)** : Implémentation de l'algorithme de transformation (encodage)

### Bonus Implémentés

#### ✅ Bonus #3 : Codage par plages (RLE - Run-Length Encoding)

Le **Run-Length Encoding** a été implémenté dans le module `RLE.hs`. Cette méthode de compression exploite les répétitions de caractères consécutifs :

- **Compression** : Les séquences de caractères identiques sont remplacées par une notation compacte

  - Les caractères uniques restent inchangés
  - Les paires (2 occurrences) sont écrites deux fois
  - Les séquences de 3+ caractères utilisent la notation `(n)c` où n est le nombre d'occurrences
  - Gère les caractères spéciaux avec échappement (`\n`, `\\`, `(`, `)`)
- **Décompression** : Reconstruction de la chaîne originale en interprétant la notation RLE

**Exemple** :

```
"AAAAAABBBCCD" → "(6)A(3)BCC(2)D"
```

#### 🔄 Bonus #4 : Combinaison des algorithmes de compression

Le tableau suivant montre le taux de compression des combinaisons des algorithmes avec différentes tailles de fichier d'entré:

| Fichier non compressé | 10 octets     | 1k octets     | 50k octets    |
| ---------------------- | ------------- | ------------- | ------------- |
| Hufmann                | - octets (-%) | - octets (-%) | - octets (-%) |
|                        |               |               |               |

#### ⚠️ Bonus #2 : Format de stockage (Partiellement implémenté)

Un format textuel a été développé pour stocker les données compressées :

- **Sérialisation de l'arbre de Huffman** : Format personnalisé avec notation `L` (feuille) et `I` (nœud interne)

  - Exemple : `I(La)(Lb)` représente un nœud interne avec deux feuilles `a` et `b`
  - Gestion des caractères spéciaux avec échappement
- **Structure du fichier** :

  - Ligne 1 : Arbre de Huffman sérialisé
  - Ligne 2 : Données binaires compressées avec RLE

**Note** : Le format est simplifié par rapport au bonus suggéré (pas de métadonnées explicites sur les fonctions utilisées ou les symboles), mais reste fonctionnel pour la compression/décompression.

## Limitations et Difficultés Rencontrées

- **BWT décompression** : L'algorithme de décompression de la transformée de Burrows-Wheeler n'est pas encore implémenté
- **Bonus #1** : La généralisation pour des symboles quelconques (au-delà des caractères) n'a pas été réalisée
- **Format de fichier** : Le format pourrait être enrichi avec plus de métadonnées (ordre de composition, statistiques, etc.)

## Tests

Des fichiers de test sont disponibles dans le répertoire `test_files/` :

- `file.txt`, `file2.txt` : Fichiers originaux
- `compressed_file.txt`, `compressed_file2.txt` : Fichiers compressés
- `decompressed_compressed_file.txt`, `decompressed_compressed_file2.txt` : Fichiers décompressés pour validation
