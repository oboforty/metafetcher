# Metafetcher
An R package implemented to link metabolites' IDs from different Metabolome databases with eachother in a step to resolve ambiguity and standardize metabolites representation and annotation.
Currently the package supports resolving IDs for the following databases:
  - Human Metabolome Database (HMDB)
  - Chemical Entities of Biological Interest (ChEBI)
  - PubChem
  - Kyoto Encyclopedia of Genes and Genomes (KEGG)
  - Lipidomics Gateway (LipidMaps)
  
 For any questions or issues please use the Issues in github or contact Rajmund Casombordi or Sara Younes.
 
 ## Installation notes and prerequsites
 
 - Install postgressql on your system
 - Install devtools in R 
 -In R write 
 ```R
library(devtools)
install_github("komorowskilab/metafetcher")
```
## Vignette 
[For how to use the package please visit (https://komorowskilab.github.io/MetaFetcher/)]

## Authors
- Rajmund Casombordi 
  @oboforty
- Sara Yones sara.younes@icm.uu.se 
 @SaraYones
- Klev Diamanti 
 @klev.diamanti
