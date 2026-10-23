# Transcript de la vidéo de démonstration

Transcription automatique de YouTube, relue et corrigée à la main (noms d'outils, fautes de transcription). Le texte suit l'ordre de la vidéo.

---

## Partie 1 : présentation du workflow

Salut. Je vais te faire la présentation de mes deux workflows. Je voulais faire une vidéo avec la caméra, mais la caméra bugue, je ne sais pas pourquoi. Donc désolé, ce sera seulement avec ma voix.

**À quoi ça sert ?** Il y a deux workflows dans le projet. Ils servent à aller chercher des comptes TikTok qui publient des posts TikTok Shop, c'est-à-dire qui vendent des produits à travers des posts : des carrousels ou des vidéos. On va récupérer des comptes, analyser leurs posts, ne garder que les carrousels, les analyser pour voir s'ils sont performants ou non, et recevoir un bilan par mail.

### Le premier workflow : la qualification des candidats

On commence par déterminer combien de candidats on veut analyser, grâce à un formulaire. Si on choisit 10, par exemple, le workflow va chercher les 10 créateurs de contenu. Pour chacun, il regarde leurs posts les plus populaires, environ 10 posts. Pour chaque post, il regarde si c'est un carrousel ou non, le nombre de vues, et s'il y a un produit affilié à la publication, c'est-à-dire un lien de produit TikTok. Il range tout ça, puis sert à décider si on garde le compte ou non.

Pour décider, on regarde trois critères :
- la médiane des vues est supérieure ou égale à 50 000 ;
- il y a plus de six posts en carrousel de deux photos ou plus ;
- il y a au moins cinq posts avec un produit.

Ensuite, on range le résultat dans le Google Sheets, qui sert au deuxième workflow. En général, on part de 10 comptes et il n'en reste que 5 retenus.

### Le deuxième workflow : le classement des carrousels et le bilan

Le deuxième workflow part des comptes retenus par le premier. Pour chaque compte, il refait une récupération des posts, mais cette fois il va plus loin : il prend jusqu'à 30 posts. Il refait ensuite des analyses : est-ce que ce sont des carrousels, est-ce qu'il y a des produits affiliés, est-ce que ce sont des posts en français. Dans cette version, on se concentre sur le marché français.

Il calcule aussi les scores de performance :
- la vitesse, c'est-à-dire le nombre de vues par heure ;
- la surperformance, c'est-à-dire le nombre de vues divisé par le nombre d'abonnés.

On multiplie ces deux valeurs, puis on prend la racine carrée : c'est ça qui donne le score de chaque carrousel. Le score nous dit si le carrousel est performant ou non. Ce classement est ensuite écrit dans le Google Sheets.

Plus bas, on a le bilan de la recherche : combien de crédits on a utilisés, combien de comptes, combien de carrousels par compte, combien de carrousels par crédit dépensé. C'est le rendement de la recherche.

Plus loin, on crée le top 10 : le workflow filtre, liste, et ne garde que les 10 meilleurs, puis les assemble.

Ensuite, on classe les catégories, pour savoir quelles catégories ressortent le plus : mode, décoration d'intérieur, et ainsi de suite. Ce sont des caractéristiques qu'on voulait retrouver dans le bilan final.

Enfin, un nœud merge rassemble trois éléments : les catégories, le top 10 et le bilan de la recherche. On envoie tout ça à Gemini, avec un prompt. Gemini renvoie sa réponse, que le workflow organise en HTML pour qu'elle apparaisse dans le mail. Par exemple, on garde cinq points clés, et on finit par l'envoi du mail.

### Ce qu'on voit dans les résultats

Je voulais exécuter les deux workflows pendant la démo, mais je n'ai plus de crédits ScrapeCreators. Les deux nœuds qui appellent l'API ScrapeCreators, pour aller scraper TikTok, s'arrêtent donc à cette étape. Je ne peux donc pas montrer l'exécution en direct. J'ai quand même le résultat à te montrer. C'est l'exécution d'hier à 18 h 41.

On voit les chiffres de la recherche : le nombre de carrousels récupérés par crédit, le nombre de crédits consommés, le nombre de carrousels gardés, le nombre de posts analysés. Ensuite, les points clés : quel compte performe, quelles catégories sont en haut du classement, quelles dynamiques se dégagent, s'il faut mettre des légendes ou des hashtags ou non. Puis la répartition des catégories dans le top 10, et le top 10 lui-même, avec les scores affichés.

Par exemple, le compte dembouzdeals a publié un carrousel à presque 5 millions de vues. Il a le meilleur score de surperformance, et environ 4 000 vues par heure.

Si on veut tout voir, on ouvre le tableau : on arrive sur le Google Sheets, avec le classement, le bilan, les candidats, et le reste. On y trouve les comptes écartés et les comptes suivis. Une fois les candidats choisis, on les range ici. Ensuite, il y a le classement des carrousels, avec le lien du produit, le lien TikTok, et le reste. Et à la fin, le bilan : les comptes interrogés, les appels réussis, les posts récupérés, et le reste.

Voilà pour le premier point. Je te laisse avec l'autre partie, qui concerne les commandes n8ncli. C'est une autre vidéo, je fais une coupure.

---

## Partie 2 : commandes n8ncli

On va faire quelques petites commandes n8ncli. Pour commencer, on lance `status` pour voir l'état actuel.

On voit quatre workflows. Il n'y a pas le workflow principal, parce que ce sont des tests. Les workflows Sandbox, on ne s'en occupe pas, on les laisse. Le mien n'apparaît pas, mais je sais que j'ai fait un tidy up après la dernière synchronisation. Il faudrait donc le pull. On peut voir avec un `diff` que ce n'est pas la même version de fichier. Il faut aller chercher le fichier principal, et on fait un `diff --summary`.

On voit qu'il n'est pas identique, parce que j'ai fait le tidy up. Donc on le récupère avec `pull`. Ensuite, on peut vérifier avec un `diff` que maintenant ils sont identiques. Et là, on voit qu'ils sont identiques : le tidy up a été synchronisé avec le fichier local.

Je continue avec les petites commandes CLI. Juste avant, j'ai demandé à Claude de traduire tout le workflow en anglais : les noms, les cards, et le reste. Sur le fichier local, c'est fait. Maintenant, il faut le pousser vers n8n.

D'abord, je valide le fichier local, pour voir s'il n'y a pas de problème de syntaxe ou de lien entre les nœuds. On lance `validate`, avec le chemin du fichier. Et j'ajoute `--no-version-check`. J'avais essayé sans, mais la commande vérifie aussi les versions des nœuds, et ça affichait beaucoup d'erreurs, alors qu'il s'agit seulement d'un petit problème de version de nœud, et que le workflow marche très bien quand même. J'ai demandé à Claude, qui m'a donné cette option à ajouter à la fin. Là, c'est valide.

Ensuite, on peut faire un `dry run`, un test à blanc, sans les vraies données. Je colle la commande. La simulation a bien marché. Elle annonce qu'elle va créer des dossiers, mais ces dossiers existent déjà sur mon n8n. Donc, en réalité, elle ne les recréera pas. Je ne sais pas pourquoi elle l'annonce, mais elle l'annonce à tort.

Maintenant, on peut faire le `push` de mon fichier local, parce qu'on sait qu'il est valide.

Le push est terminé. C'est moi qui ai fait le petit montage. Je te fais une outro : désolé encore pour l'exécution, et pour la caméra. Je te souhaite du courage pour revoir toutes les vidéos de tout le monde. À bientôt.
