# PF_Haskell

Projet de compression de fichiers en Haskell utilisant plusieurs algorithmes de compression.

## Compilation

```bash
cabal build
```

## Utilisation

### Compression

Pour compresser un fichier, utilisez l'option `-c` suivie du chemin du fichier et de la chaîne d'algorithmes :

```bash
cabal run Main.hs -- -c <chemin_fichier> <algorithmes>
```

**Exemples :**

```bash
# Compression avec Huffman uniquement
cabal run Main.hs -- -c test_files/file10B.txt huffman

# Compression avec BWT puis RLE
cabal run Main.hs -- -c test_files/file10B.txt bwt-rle

# Compression avec une chaîne d'algorithmes : Huffman, BWT, RLE, puis Huffman
cabal run Main.hs -- -c test_files/file10B.txt huffman-bwt-rle-huffman
```

**Algorithmes disponibles :**

- `huffman` : Codage de Huffman
- `bwt` : Transformée de Burrows-Wheeler
- `rle` : Run-Length Encoding

Les algorithmes sont appliqués dans l'ordre spécifié, séparés par des tirets (`-`).

Le fichier compressé sera créé dans le même répertoire avec le préfixe `compressed_` et contiendra la chaîne d'algorithmes utilisés en première ligne.

### Décompression

Pour décompresser un fichier, utilisez l'option `-d` suivie du chemin du fichier compressé :

```bash
cabal run Main.hs -- -d <chemin_fichier_compressé>
```

**Exemple :**

```bash
cabal run Main.hs -- -d test_files/compressed_file10B.txt
```

**Note :** La chaîne d'algorithmes est automatiquement lue depuis la première ligne du fichier compressé, il n'est donc pas nécessaire de la spécifier lors de la décompression.

Le fichier décompressé sera créé dans le même répertoire avec le préfixe `decompressed_`.

## Structure des fichiers

```
PF_Haskell/
├── app/
│   └── Main.hs           # Point d'entrée du programme
├── src/
│   ├── Huffman.hs        # Implémentation du codage de Huffman
│   ├── BWT.hs            # Implémentation de la transformée de Burrows-Wheeler
│   └── RLE.hs            # Implémentation du Run-Length Encoding
├── test_files/           # Fichiers de test
└── README.md
```

## Format des fichiers compressés

Les fichiers compressés ont le format suivant :

```
<chaîne_algorithmes>
<métadonnées_algo1>
<métadonnées_algo2>
...
<contenu_compressé>
```

Exemple pour `huffman-bwt` :

```
huffman-bwt
<arbre_huffman>
<index_bwt>
<chaîne_compressée>
```

## Bibliothèques Utilisées

- **Data.Map** : Utilisée dans le module Huffman pour créer une correspondance efficace entre caractères et leurs codes binaires
- **Data.List** : Utilisée pour les opérations de tri dans la transformée de Burrows-Wheeler
- **System.FilePath** : Pour la manipulation des chemins de fichiers (lecture/écriture)
- **Data.List.Split** : Pour parser la chaîne d'algorithmes lors de la décompression

## Fonctionnalités Implémentées

### Fonctionnalités de Base

✅ **Codage de Huffman** : Compression et décompression complètes avec construction d'arbre de codes
✅ **Transformée de Burrows-Wheeler (BWT)** : Implémentation de l'algorithme de transformation (encodage)

### Bonus Implémentés

#### Bonus #2 : Format de stockage

Un **format de fichier structuré** a été implémenté pour permettre la décompression automatique sans spécifier manuellement les algorithmes utilisés :

- **Ligne 1** : Chaîne d'algorithmes utilisés (ex: `huffman-bwt-rle`)
- **Lignes suivantes** : Métadonnées de chaque algorithme (arbre Huffman, index BWT, etc.)
- **Dernière ligne** : Contenu compressé final

Ce format permet une décompression autonome : le programme lit automatiquement la chaîne d'algorithmes et applique les décompressions dans l'ordre inverse avec les métadonnées appropriées.

Pour l'arbre de Huffman, le format utilisé est le suivant:

Feuilles: `L<char>`
Noeuds internes: `I(<left>)(<right>)`
Exemple: `I(La)(Lb)`

#### Bonus #3 : Codage par plages (RLE - Run-Length Encoding)

Le **Run-Length Encoding** a été implémenté dans le module `RLE.hs`. Cette méthode de compression exploite les répétitions de caractères consécutifs :

- **Compression** : Les séquences de caractères identiques sont remplacées par une notation compacte

  - Si un caractère se répète 4 fois ou moins, il est laissé tel quel.
  - Les séquences d'au moins 5 caractères utilisent la notation `(n)c` où n est le nombre d'occurrences
  - Gère les caractères spéciaux avec échappement (`\n`, `\\`, `(`, `)`)
- **Décompression** : Reconstruction de la chaîne originale en interprétant la notation RLE

**Exemple** :

```
"AAAAAABBBCCD" → "(6)ABBBCCD"
```

#### Bonus #4 : Combinaison des algorithmes de compression

**Conjectures:**

1. **Petits fichiers (< 500o)** : Huffman seul est plus efficace car les métadonnées des autres algorithmes (index BWT, format RLE) dominent la taille finale
2. **Fichiers moyens/grands (> 2ko)** : BWT-RLE-Huffman devrait être optimal car BWT regroupe les caractères similaires, permettant à RLE d'exploiter ces répétitions
3. **Ordre optimal pour les fichiers de très grande taille** : Appliquer BWT-RLE- Huffman sur une séquence de bits plutôt que sur la chaîne de caractère en entrée pourrait permettre de regrouper plus de répétions

Le tableau suivant montre le taux de compression des combinaisons des algorithmes avec différentes tailles de fichier d'entré. **Les séquences d'algorithmes avec une croix rouge produisent une chaîne de charactères finale qui n'est pas seulement composée de bits**:

| Fichiers non compressés | 10o | 500o | 2ko    | 50ko    |
| ------------------------ | --- | ---- | ------ | ------- |
| Huffman                  | 63o | 481o | 1.52ko | 28.58ko |
| BWT ❌                   | 16o | 507o | 2.06ko | 51.16ko |
| RLE ❌                   | 14o | 504o | 2.05ko | 51.09ko |
| BWT-Huffman              | 69o | 488o | 1.55ko | 29.16ko |
| BWT-RLE-Huffman          | 73o | 526o | 1.66ko | 27.79ko |
| Huffman-BWT-RLE-Huffman  | 91o | 775o | 2.4ko  |         |

**Observations:**

1. Les fichiers de 10o deviennent plus volumineux (63-91o) à cause des métadonnées
2. Sur 50ko, **BWT-RLE-Huffman** offre le meilleur taux de compression
3. Les longues chaînes d'algorithmes causent des problèmes de performance sur gros fichiers
4. Appliquer BWT-RLE-Huffman sur la séquence de bits de sortie de l'algorithme de Huffman n'est en fait pas une bonne idée car essayer de regrouper plus de répétitions est contre-balancé par le fait que les bits sont eux-mêmes ré-encodé par plusieurs bits (cette observation n'a pas pu être confirmée sur le fichier de 50ko car la compression est trop lente)
