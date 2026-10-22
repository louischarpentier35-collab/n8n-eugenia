const qualifier_les_candidats = trigger({
  type: 'n8n-nodes-base.formTrigger',
  version: 2.6,
  config: { name: 'Qualifier les candidats', parameters: { formTitle: 'Qualifier les comptes candidats', formDescription: 'Analyse les candidats « à qualifier » de l\'onglet Candidats. Coût : 1 crédit ScrapeCreators par candidat.', formFields: { values: [{ fieldLabel: 'Nombre maximum de candidats', fieldType: 'number', fieldName: 'nb_max', defaultValue: '15', requiredField: true }] }, options: { appendAttribution: false, buttonLabel: 'Lancer la qualification' } }, webhookId: '5d3d6b11-e621-4917-9344-027687bba886' }
});

const lire_les_candidats_qualifier = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Lire les candidats à qualifier', parameters: { documentId: { __rl: true, mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw', cachedResultName: 'Veille carrousels TikTok Shop' }, sheetName: { __rl: true, mode: 'name', value: 'Candidats' }, filtersUI: { values: [{ lookupColumn: 'statut', lookupValue: 'à qualifier' }] }, options: {} }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [224, 0] }
});

const limiter_le_nombre_de_candidats = node({
  type: 'n8n-nodes-base.limit',
  version: 1,
  config: { name: 'Limiter le nombre de candidats', parameters: { maxItems: expr('{{ Number($(\'Qualifier les candidats\').first().json.nb_max ?? $(\'Qualifier les candidats\').first().json[\'Nombre maximum de candidats\']) || 15 }}') }, position: [448, 0] }
});

const posts_populaires_du_candidat = node({
  type: 'n8n-nodes-base.httpRequest',
  version: 4.2,
  config: { name: 'Posts populaires du candidat', parameters: { url: 'https://api.scrapecreators.com/v3/tiktok/profile/videos', authentication: 'genericCredentialType', genericAuthType: 'httpHeaderAuth', sendQuery: true, queryParameters: { parameters: [{ name: 'handle', value: expr('{{ $json.handle }}') }, { name: 'sort_by', value: 'popular' }, { name: 'region', value: 'FR' }] }, options: {} }, credentials: { httpHeaderAuth: newCredential('ScrapeCreators', '4N212Cewm1RMlzmU') }, position: [672, 0], onError: 'continueErrorOutput' }
});

const s_parer_les_10_posts = node({
  type: 'n8n-nodes-base.splitOut',
  version: 1.1,
  config: { name: 'Séparer les 10 posts', parameters: { fieldToSplitOut: 'aweme_list', options: {} }, position: [880, 0] }
});

const analyser_chaque_post = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Analyser chaque post', parameters: { assignments: { assignments: [{ id: 'f-handle', name: 'handle', value: expr('{{ $json.author.unique_id }}'), type: 'string' }, { id: 'f-abonnes', name: 'abonnes', value: expr('{{ $json.author.follower_count }}'), type: 'number' }, { id: 'f-carrousel', name: 'est_carrousel', value: expr('{{ $json.content_type === \'multi_photo\' && ($json.image_post_info?.images?.length ?? 0) >= 2 ? 1 : 0 }}'), type: 'number' }, { id: 'f-produit', name: 'a_produit', value: expr('{{ $json.shop_product_url ? 1 : 0 }}'), type: 'number' }, { id: 'f-vues', name: 'vues', value: expr('{{ $json.statistics.play_count }}'), type: 'number' }] }, options: {} }, position: [1104, 0] }
});

const r_sumer_par_candidat = node({
  type: 'n8n-nodes-base.summarize',
  version: 1.1,
  config: { name: 'Résumer par candidat', parameters: { fieldsToSummarize: { values: [{ aggregation: 'sum', field: 'est_carrousel' }, { aggregation: 'sum', field: 'a_produit' }, { aggregation: 'max', field: 'abonnes' }, { aggregation: 'append', field: 'vues' }] }, fieldsToSplitBy: 'handle', options: {} }, position: [1328, 0] }
});

const calculer_les_indicateurs = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Calculer les indicateurs', parameters: { assignments: { assignments: [{ id: 'i-handle', name: 'handle', value: expr('{{ $json.handle }}'), type: 'string' }, { id: 'i-abonnes', name: 'abonnes', value: expr('{{ $json.max_abonnes }}'), type: 'number' }, { id: 'i-carr', name: 'nb_carrousels', value: expr('{{ $json.sum_est_carrousel }}'), type: 'number' }, { id: 'i-prod', name: 'nb_avec_produit', value: expr('{{ $json.sum_a_produit }}'), type: 'number' }, { id: 'i-med', name: 'vues_mediane', value: expr('{{ $json.appended_vues.map(Number).sort((a, b) => a - b)[Math.floor($json.appended_vues.length / 2)] }}'), type: 'number' }, { id: 'i-date', name: 'date_qualification', value: expr('{{ $now.toFormat(\'dd/MM/yyyy\') }}'), type: 'string' }] }, options: {} }, position: [1552, 0] }
});

const compte_qualifi = node({
  type: 'n8n-nodes-base.if',
  version: 2.2,
  config: { name: 'Compte qualifié ?', parameters: { conditions: { options: { caseSensitive: true, leftValue: '', typeValidation: 'loose', version: 1 }, conditions: [{ leftValue: expr('{{ $json.nb_carrousels }}'), operator: { type: 'number', operation: 'gte' }, rightValue: 6 }, { leftValue: expr('{{ $json.nb_avec_produit }}'), operator: { type: 'number', operation: 'gte' }, rightValue: 5 }, { leftValue: expr('{{ $json.vues_mediane }}'), operator: { type: 'number', operation: 'gt' }, rightValue: 50000 }], combinator: 'and' }, options: {} }, position: [1760, 0] }
});

const statut_suivi = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Statut : suivi', parameters: { assignments: { assignments: [{ id: 's-suivi', name: 'statut', value: 'suivi', type: 'string' }] }, includeOtherFields: true, options: {} }, position: [1984, -128] }
});

const mettre_jour_le_candidat = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Mettre à jour le candidat', parameters: { operation: 'update', documentId: { __rl: true, mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw', cachedResultName: 'Veille carrousels TikTok Shop' }, sheetName: { __rl: true, mode: 'name', value: 'Candidats' }, columns: { mappingMode: 'defineBelow', matchingColumns: ['handle'], value: { handle: expr('{{ $json.handle }}'), statut: expr('{{ $json.statut }}'), nb_carrousels: expr('{{ $json.nb_carrousels }}'), nb_avec_produit: expr('{{ $json.nb_avec_produit }}'), vues_mediane: expr('{{ $json.vues_mediane }}'), date_qualification: expr('{{ $json.date_qualification }}') }, schema: [{ id: 'handle', displayName: 'handle', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'statut', displayName: 'statut', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'nb_carrousels', displayName: 'nb_carrousels', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'nb_avec_produit', displayName: 'nb_avec_produit', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'vues_mediane', displayName: 'vues_mediane', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'date_qualification', displayName: 'date_qualification', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }] }, options: {} }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [2240, 0] }
});

const ajouter_aux_comptes_suivis = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Ajouter aux comptes suivis', parameters: { operation: 'append', documentId: { __rl: true, mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw', cachedResultName: 'Veille carrousels TikTok Shop' }, sheetName: { __rl: true, mode: 'name', value: 'Comptes suivis' }, columns: { mappingMode: 'defineBelow', value: { handle: expr('{{ $json.handle }}'), abonnes: expr('{{ $json.abonnes }}'), date_ajout: expr('{{ $json.date_qualification }}') }, schema: [{ id: 'handle', displayName: 'handle', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'abonnes', displayName: 'abonnes', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'date_ajout', displayName: 'date_ajout', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }] }, options: {} }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [2240, -240] }
});

const statut_cart = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Statut : écarté', parameters: { assignments: { assignments: [{ id: 's-ecarte', name: 'statut', value: 'écarté', type: 'string' }] }, includeOtherFields: true, options: {} }, position: [1984, 128] }
});

const lancer_la_collecte = trigger({
  type: 'n8n-nodes-base.manualTrigger',
  version: 1,
  config: { name: 'Lancer la collecte', position: [0, 704] }
});

const lire_les_comptes_suivis = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Lire les comptes suivis', parameters: { documentId: { __rl: true, mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw', cachedResultName: 'Veille carrousels TikTok Shop' }, sheetName: { __rl: true, mode: 'name', value: 'Comptes suivis' }, options: {} }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [224, 704] }
});

const posts_populaires_du_compte_suivi = node({
  type: 'n8n-nodes-base.httpRequest',
  version: 4.2,
  config: { name: 'Posts populaires du compte suivi', parameters: { url: 'https://api.scrapecreators.com/v3/tiktok/profile/videos', authentication: 'genericCredentialType', genericAuthType: 'httpHeaderAuth', sendQuery: true, queryParameters: { parameters: [{ name: 'handle', value: expr('{{ $json.handle }}') }, { name: 'sort_by', value: 'popular' }, { name: 'region', value: 'FR' }] }, options: { pagination: { pagination: { paginationMode: 'updateAParameterInEachRequest', parameters: { parameters: [{ type: 'qs', name: 'max_cursor', value: expr('{{ $response.body.max_cursor }}') }] }, paginationCompleteWhen: 'other', completeExpression: expr('{{ !$response.body.has_more || !$response.body.max_cursor }}'), limitPagesFetched: true, maxRequests: 3 } } } }, credentials: { httpHeaderAuth: newCredential('ScrapeCreators', '4N212Cewm1RMlzmU') }, position: [448, 704], onError: 'continueErrorOutput' }
});

const s_parer_les_posts = node({
  type: 'n8n-nodes-base.splitOut',
  version: 1.1,
  config: { name: 'Séparer les posts', parameters: { fieldToSplitOut: 'aweme_list', options: {} }, position: [672, 704] }
});

const garder_les_carrousels_shoppables = node({
  type: 'n8n-nodes-base.filter',
  version: 2.2,
  config: { name: 'Garder les carrousels shoppables', parameters: { conditions: { options: { caseSensitive: true, leftValue: '', typeValidation: 'loose', version: 1 }, conditions: [{ leftValue: expr('{{ $json.content_type }}'), operator: { type: 'string', operation: 'equals' }, rightValue: 'multi_photo' }, { leftValue: expr('{{ $json.image_post_info?.images?.length ?? 0 }}'), operator: { type: 'number', operation: 'gte' }, rightValue: 2 }, { leftValue: expr('{{ $json.shop_product_url ?? \'\' }}'), operator: { type: 'string', operation: 'notEmpty', singleValue: true }, rightValue: '' }], combinator: 'and' }, options: {} }, position: [880, 704] }
});

const garder_les_l_gendes_en_fran_ais = node({
  type: 'n8n-nodes-base.filter',
  version: 2.2,
  config: { name: 'Garder les légendes en français', parameters: { conditions: { options: { caseSensitive: true, leftValue: '', typeValidation: 'loose', version: 1 }, conditions: [{ leftValue: expr('{{ ((t) => /[èêàçùœ]|\\b(les|des|du|est|pour|avec|cette|ces|mes|vous|je|nous|pas|très|mais|dans|chez|voici|voilà|ça|trop|enfin|aussi|encore)\\b|\\bc\'est\\b|\\bj\'ai\\b/.test(t) ? \'fr\' : (/[a-zà-ÿ]{3,}/.test(t) ? \'autre\' : ($json.text_sticker_major_lang === \'fr\' || ($json.region === \'FR\' && $json.author?.language === \'fr\') ? \'fr\' : \'autre\')))(($json.desc ?? \'\').replace(/#\\S+/g, \' \').replace(/@\\S+/g, \' \').toLowerCase()) }}'), operator: { type: 'string', operation: 'equals' }, rightValue: 'fr' }], combinator: 'and' }, options: {} }, position: [992, 704] }
});

const calculer_les_scores = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Calculer les scores', parameters: { assignments: { assignments: [{ id: 'r-id', name: 'id_post', value: expr('{{ String($json.aweme_id) }}'), type: 'string' }, { id: 'r-lien', name: 'lien', value: expr('https://www.tiktok.com/@{{ $json.author.unique_id }}/photo/{{ $json.aweme_id }}'), type: 'string' }, { id: 'r-date', name: 'date_publication', value: expr('{{ DateTime.fromSeconds(Number($json.create_time)).toFormat(\'dd/MM/yyyy\') }}'), type: 'string' }, { id: 'r-vues', name: 'vues', value: expr('{{ $json.statistics.play_count }}'), type: 'number' }, { id: 'r-likes', name: 'likes', value: expr('{{ $json.statistics.digg_count }}'), type: 'number' }, { id: 'r-saves', name: 'saves', value: expr('{{ $json.statistics.collect_count }}'), type: 'number' }, { id: 'r-partages', name: 'partages', value: expr('{{ $json.statistics.share_count }}'), type: 'number' }, { id: 'r-handle', name: 'handle', value: expr('{{ $json.author.unique_id }}'), type: 'string' }, { id: 'r-abonnes', name: 'abonnes', value: expr('{{ $json.author.follower_count }}'), type: 'number' }, { id: 'r-vitesse', name: 'vitesse', value: expr('{{ Math.round($json.statistics.play_count / Math.max(1, ($now.toSeconds() - Number($json.create_time)) / 3600)) }}'), type: 'number' }, { id: 'r-surperf', name: 'surperformance', value: expr('{{ Math.round($json.statistics.play_count / Math.max(1, $json.author.follower_count) * 10) / 10 }}'), type: 'number' }, { id: 'r-score', name: 'score', value: expr('{{ Math.round(Math.sqrt(($json.statistics.play_count / Math.max(1, ($now.toSeconds() - Number($json.create_time)) / 3600)) * ($json.statistics.play_count / Math.max(1, $json.author.follower_count)))) }}'), type: 'number' }, { id: 'r-produit', name: 'produit', value: expr('{{ ((p) => ((i) => p(i.extra ?? \'{}\').title || i.keyword || \'\')((p($json.anchors?.[0]?.extra ?? \'[]\') ?? [])[0] ?? {}))((x) => typeof x === \'string\' ? JSON.parse(x) : x) }}'), type: 'string' }, { id: 'r-lienprod', name: 'lien_produit', value: expr('{{ $json.shop_product_url }}'), type: 'string' }, { id: 'r-cat', name: 'categorie', value: expr('{{ ((p) => ((i) => p(i.extra ?? \'{}\').categories?.[0]?.category_name ?? \'\')((p($json.anchors?.[0]?.extra ?? \'[]\') ?? [])[0] ?? {}))((x) => typeof x === \'string\' ? JSON.parse(x) : x) }}'), type: 'string' }, { id: 'r-legende', name: 'legende', value: expr('{{ $json.desc ?? \'\' }}'), type: 'string' }, { id: 'r-hashtags', name: 'hashtags', value: expr('{{ ($json.text_extra ?? []).filter(t => t.hashtag_name).map(t => \'#\' + t.hashtag_name).join(\' \') }}'), type: 'string' }, { id: 'r-slides', name: 'nb_slides', value: expr('{{ $json.image_post_info.images.length }}'), type: 'number' }, { id: 'r-son', name: 'son', value: expr('{{ ($json.music?.title ?? \'\') + \' – \' + ($json.music?.author ?? \'\') }}'), type: 'string' }, { id: 'r-source', name: 'source', value: 'compte', type: 'string' }, { id: 'r-trouve', name: 'date_trouve', value: expr('{{ $now.toFormat(\'dd/MM/yyyy\') }}'), type: 'string' }] }, options: {} }, position: [1120, 704] }
});

const crire_dans_le_classement = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Écrire dans le classement', parameters: { operation: 'appendOrUpdate', documentId: { __rl: true, mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw', cachedResultName: 'Veille carrousels TikTok Shop' }, sheetName: { __rl: true, mode: 'name', value: 'Classement' }, columns: { mappingMode: 'autoMapInputData', matchingColumns: ['id_post'], value: {}, schema: [{ id: 'id_post', displayName: 'id_post', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'lien', displayName: 'lien', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'date_publication', displayName: 'date_publication', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'vues', displayName: 'vues', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'likes', displayName: 'likes', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'saves', displayName: 'saves', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'partages', displayName: 'partages', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'handle', displayName: 'handle', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'abonnes', displayName: 'abonnes', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'vitesse', displayName: 'vitesse', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'surperformance', displayName: 'surperformance', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'score', displayName: 'score', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'produit', displayName: 'produit', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'lien_produit', displayName: 'lien_produit', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'categorie', displayName: 'categorie', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'legende', displayName: 'legende', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'hashtags', displayName: 'hashtags', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'nb_slides', displayName: 'nb_slides', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'son', displayName: 'son', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'source', displayName: 'source', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'date_trouve', displayName: 'date_trouve', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }] }, options: { cellFormat: 'RAW', handlingExtraData: 'ignoreIt' } }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [1344, 464] }
});

const compter_par_compte = node({
  type: 'n8n-nodes-base.summarize',
  version: 1.1,
  config: { name: 'Compter par compte', parameters: { fieldsToSummarize: { values: [{ field: 'id_post' }] }, fieldsToSplitBy: 'handle', options: {} }, position: [1344, 832] }
});

const pr_parer_le_suivi_des_comptes = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Préparer le suivi des comptes', parameters: { assignments: { assignments: [{ id: 'c-handle', name: 'handle', value: expr('{{ $json.handle }}'), type: 'string' }, { id: 'c-date', name: 'dernier_lancement', value: expr('{{ $now.toFormat(\'dd/MM/yyyy\') }}'), type: 'string' }, { id: 'c-nb', name: 'carrousels_trouves', value: expr('{{ $json.count_id_post }}'), type: 'number' }, { id: 'c-rend', name: 'rendement', value: expr('{{ $json.count_id_post }}'), type: 'number' }] }, options: {} }, position: [1568, 832] }
});

const mettre_jour_les_comptes_suivis = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Mettre à jour les comptes suivis', parameters: { operation: 'update', documentId: { __rl: true, mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw', cachedResultName: 'Veille carrousels TikTok Shop' }, sheetName: { __rl: true, mode: 'name', value: 'Comptes suivis' }, columns: { mappingMode: 'autoMapInputData', matchingColumns: ['handle'], value: {}, schema: [{ id: 'handle', displayName: 'handle', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'dernier_lancement', displayName: 'dernier_lancement', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'carrousels_trouves', displayName: 'carrousels_trouves', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }, { id: 'rendement', displayName: 'rendement', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true }] }, options: { handlingExtraData: 'ignoreIt' } }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [1792, 832] }
});

const calculer_le_bilan_du_lancement = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Calculer le bilan du lancement', parameters: { assignments: { assignments: [{ id: 'b-date', name: 'date_lancement', type: 'string', value: expr('{{ $now.toFormat(\'dd/MM/yyyy HH:mm\') }}') }, { id: 'b-comptes', name: 'comptes_interroges', type: 'number', value: expr('{{ $(\'Lire les comptes suivis\').all().length }}') }, { id: 'b-ok', name: 'appels_reussis', type: 'number', value: expr('{{ $(\'Posts populaires du compte suivi\').all(0).length }}') }, { id: 'b-ko', name: 'appels_en_echec', type: 'number', value: expr('{{ Math.max(0, $(\'Lire les comptes suivis\').all().length - new Set($(\'Séparer les posts\').all().map(i => i.json.author?.unique_id)).size) }}') }, { id: 'b-posts', name: 'posts_recuperes', type: 'number', value: expr('{{ $(\'Séparer les posts\').all().length }}') }, { id: 'b-carr', name: 'carrousels_shoppables', type: 'number', value: expr('{{ $(\'Garder les légendes en français\').all().length }}') }, { id: 'b-nonfr', name: 'carrousels_ecartes_langue', type: 'number', value: expr('{{ $(\'Garder les carrousels shoppables\').all().length - $(\'Garder les légendes en français\').all().length }}') }, { id: 'b-part', name: 'part_shoppable', type: 'string', value: expr('{{ Math.round($(\'Garder les légendes en français\').all().length / Math.max(1, $(\'Séparer les posts\').all().length) * 1000) / 10 + \' %\' }}') }, { id: 'b-credits', name: 'credits_consommes', type: 'number', value: expr('{{ $(\'Posts populaires du compte suivi\').all(0).length }}') }, { id: 'b-rend', name: 'carrousels_par_credit', type: 'number', value: expr('{{ Math.round($(\'Garder les légendes en français\').all().length / Math.max(1, $(\'Posts populaires du compte suivi\').all(0).length) * 10) / 10 }}') }] }, options: {} }, position: [2000, 832], executeOnce: true }
});

const crire_le_bilan = node({
  type: 'n8n-nodes-base.googleSheets',
  version: 4.7,
  config: { name: 'Écrire le bilan', parameters: { operation: 'append', documentId: { __rl: true, cachedResultName: 'Veille carrousels TikTok Shop', mode: 'id', value: '1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw' }, sheetName: { __rl: true, mode: 'name', value: 'Bilan' }, columns: { mappingMode: 'autoMapInputData', schema: [{ canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'date_lancement', id: 'date_lancement', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'comptes_interroges', id: 'comptes_interroges', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'appels_reussis', id: 'appels_reussis', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'appels_en_echec', id: 'appels_en_echec', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'posts_recuperes', id: 'posts_recuperes', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'carrousels_shoppables', id: 'carrousels_shoppables', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'part_shoppable', id: 'part_shoppable', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'credits_consommes', id: 'credits_consommes', required: false, type: 'string' }, { canBeUsedToMatch: true, defaultMatch: false, display: true, displayName: 'carrousels_par_credit', id: 'carrousels_par_credit', required: false, type: 'string' }], value: {} }, options: { locationDefine: { values: {} }, handlingExtraData: 'ignoreIt' } }, credentials: { googleSheetsOAuth2Api: newCredential('Google Sheets account', '2TJCTmq9cW1aqdsz') }, position: [2224, 832] }
});

const pr_parer_le_top_10 = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: { name: 'Préparer le top 10', parameters: { assignments: { assignments: [{ id: 't-html', name: 'top10_html', type: 'string', value: expr('{{ $(\'Calculer les scores\').all().map(i => i.json).sort((a, b) => b.score - a.score).slice(0, 10).map((c, k) => \'<tr><td>\' + (k + 1) + \'</td><td><a href="\' + c.lien + \'">@\' + c.handle + \'</a></td><td>\' + String(c.produit || \'\').slice(0, 60) + \'</td><td>\' + (c.categorie || \'\') + \'</td><td>\' + Number(c.vues).toLocaleString(\'fr-FR\') + \'</td><td>× \' + c.surperformance + \'</td><td>\' + Number(c.vitesse).toLocaleString(\'fr-FR\') + \' /h</td><td><b>\' + c.score + \'</b></td></tr>\').join(\'\') }}') }, { id: 't-texte', name: 'top10_texte', type: 'string', value: expr('{{ $(\'Calculer les scores\').all().map(i => i.json).sort((a, b) => b.score - a.score).slice(0, 10).map((c, k) => (k + 1) + \'. @\' + c.handle + \' (\' + c.abonnes + \' abonnés) | produit : \' + c.produit + \' | catégorie : \' + c.categorie + \' | \' + c.nb_slides + \' slides | publié le \' + c.date_publication + \' | \' + c.vues + \' vues, \' + c.saves + \' saves, \' + c.partages + \' partages | surperformance x\' + c.surperformance + \' | vitesse \' + c.vitesse + \' vues/h | légende : \' + String(c.legende || \'\').slice(0, 120)).join(\'\\n\') }}') }] }, includeOtherFields: true, options: {} }, position: [2240, 1120], executeOnce: true }
});

const r_diger_le_commentaire_Gemini = node({
  type: '@n8n/n8n-nodes-langchain.googleGemini',
  version: 1.2,
  config: { name: 'Rédiger le commentaire (Gemini)', parameters: { modelId: { __rl: true, mode: 'list', value: 'models/gemini-3-flash-preview' }, messages: { values: [{ content: expr('{{ \'Voici le top 10 des carrousels TikTok Shop les plus performants trouvés lors de la veille du \' + $json.date_lancement + \' (\' + $json.carrousels_shoppables + \' carrousels shoppables trouvés sur \' + $json.posts_recuperes + \' posts analysés) :\\n\\n\' + $json.top10_texte + \'\\n\\nRédige en français un commentaire de 4 à 6 phrases sur les tendances observées : catégories de produits qui dominent, nombre de slides, formats ou accroches visibles dans les légendes, comptes qui surperforment. Reste factuel et appuie-toi uniquement sur ces données, sans rien inventer. Texte brut, sans titre, sans liste, sans markdown.\' }}') }] }, builtInTools: { googleSearch: false, urlContext: false, codeExecution: false }, options: { includeMergedResponse: true, systemMessage: 'Tu es un analyste de contenus TikTok Shop. Tu écris des synthèses courtes, factuelles et utiles pour un créateur de carrousels.', maxOutputTokens: 800, temperature: 0.4, thinkingBudget: 0 } }, credentials: { googlePalmApi: newCredential('Default Gemini Projet - louis.charpentier35@gmail.com', 'Dp1pRBRk23gBnzkG') }, position: [2464, 1120], onError: 'continueRegularOutput' }
});

const envoyer_le_r_capitulatif = node({
  type: 'n8n-nodes-base.gmail',
  version: 2.2,
  config: { name: 'Envoyer le récapitulatif', parameters: { sendTo: 'louis.charpentier35@gmail.com', subject: expr('{{ \'Veille carrousels TikTok Shop – \' + $(\'Préparer le top 10\').first().json.date_lancement + \' – \' + $(\'Préparer le top 10\').first().json.carrousels_shoppables + \' carrousels\' }}'), message: expr('{{ (() => { const b = $(\'Préparer le top 10\').first().json; const commentaire = $json.mergedResponse || $json.content?.parts?.[0]?.text || $json.text || \'Commentaire indisponible (Gemini n\\\'a pas répondu).\'; return \'<div style="font-family:Arial,sans-serif;color:#222"><h2>Veille carrousels TikTok Shop</h2><p>Lancement du \' + b.date_lancement + \'</p><h3>Ce qu\\\'il faut retenir</h3><p>\' + commentaire + \'</p><h3>Top 10 du lancement</h3><table cellpadding="6" style="border-collapse:collapse;font-size:13px" border="1"><tr style="background:#f2f2f2"><th>#</th><th>Compte</th><th>Produit</th><th>Catégorie</th><th>Vues</th><th>Surperf.</th><th>Vitesse</th><th>Score</th></tr>\' + b.top10_html + \'</table><h3>Chiffres clés</h3><ul><li>Comptes interrogés : \' + b.comptes_interroges + \' (\' + b.appels_en_echec + \' en échec)</li><li>Posts analysés : \' + b.posts_recuperes + \'</li><li>Carrousels shoppables : \' + b.carrousels_shoppables + \' (\' + b.part_shoppable + \' des posts)</li><li>Crédits consommés : \' + b.credits_consommes + \' (\' + b.carrousels_par_credit + \' carrousels par crédit)</li></ul><p><a href="https://docs.google.com/spreadsheets/d/1mBPBRFu51oXvl50q-jhLrykzO5pdq1-ZNvxatjyVWJw/edit">Ouvrir le tableau complet</a></p></div>\'; })() }}'), options: { appendAttribution: false, senderName: 'Veille carrousels' } }, credentials: { gmailOAuth2: newCredential('Gmail account', 'EFtg5pjrkF3hmyH2') }, position: [2688, 1120], webhookId: '882046d8-588e-481c-bfa2-1b9955658e05', executeOnce: true }
});

const wf = workflow('nSJpAqk278rccpWA', 'Veille carrousels TikTok Shop', { executionOrder: 'v1', availableInMCP: true, binaryMode: 'separate' });

export default wf
  .add(qualifier_les_candidats)
  .to(lire_les_candidats_qualifier)
  .to(limiter_le_nombre_de_candidats)
  .to(posts_populaires_du_candidat)
  .to(s_parer_les_10_posts)
  .to(analyser_chaque_post)
  .to(r_sumer_par_candidat)
  .to(calculer_les_indicateurs)
  .to(compte_qualifi.onTrue(statut_suivi
    .to([
      mettre_jour_le_candidat,
      ajouter_aux_comptes_suivis])).onFalse(statut_cart
    .to(mettre_jour_le_candidat)))
  .add(lancer_la_collecte)
  .to(lire_les_comptes_suivis)
  .to(posts_populaires_du_compte_suivi)
  .to(s_parer_les_posts)
  .to(garder_les_carrousels_shoppables)
  .to(garder_les_l_gendes_en_fran_ais)
  .to(calculer_les_scores
  .to([
    crire_dans_le_classement,
    compter_par_compte
    .to(pr_parer_le_suivi_des_comptes)
    .to(mettre_jour_les_comptes_suivis)
    .to(calculer_le_bilan_du_lancement
    .to([
      crire_le_bilan,
      pr_parer_le_top_10
      .to(r_diger_le_commentaire_Gemini)
      .to(envoyer_le_r_capitulatif)]))]))
  .add(sticky('## 1. Qualification des candidats\nÀ lancer quand tu ajoutes des candidats, via le formulaire (choisis le nombre maximum de candidats à traiter). Coût : 1 crédit par candidat.\n\nCritères pour devenir « suivi » : au moins 6 carrousels de 2 images ou plus, au moins 5 posts avec produit, vues médianes > 50 000.', [], { name: 'Sticky Note 405ab420', color: 5, width: 384, height: 224, position: [192, -384] }))
  .add(sticky('## 2. Collecte des carrousels\nÀ lancer à chaque veille. Pour chaque compte suivi : les 30 posts les plus populaires, en 3 pages de 10 (pagination max_cursor, 1 crédit par page, donc jusqu\'à 3 crédits par compte). On garde les carrousels de 2 images ou plus liés à un produit TikTok Shop, puis seulement ceux en français (légende en français ; si la légende n\'a que des hashtags : texte des slides en français, ou post et auteur FR).\n\nvitesse = vues par heure ; surperformance = vues ÷ abonnés ; score = racine carrée de (vitesse × surperformance). Le classement est mis à jour par id_post (pas de doublon, stats rafraîchies).', [], { name: 'Sticky Note 0a91c250', color: 4, width: 384, height: 224, position: [192, 320] }))
  .add(sticky('## Étape 1 : lire les comptes suivis\nOn lit l\'onglet « Comptes suivis » du Google Sheet. Une ligne = un créateur qu\'on surveille.', [], { name: 'Card 1 - Comptes suivis', color: 4, width: 300, height: 200, position: [0, 1000] }))
  .add(sticky('## Étape 2 : 30 posts populaires par compte\nPour chaque compte : 3 pages de 10 posts, tri « popular », région FR. Chaque page coûte 1 crédit ScrapeCreators. TikTok renvoie un curseur (max_cursor) pour passer à la page suivante.', [], { name: 'Card 2 - Pages popular', color: 4, width: 300, height: 200, position: [340, 1000] }))
  .add(sticky('## Étape 3 : garder les carrousels shoppables\nOn garde les posts photo (multi_photo) avec au moins 2 images ET un produit TikTok Shop lié. Les vidéos sont écartées : on ne paie pas pour elles.', [], { name: 'Card 3 - Carrousels shoppables', color: 4, width: 300, height: 200, position: [680, 1000] }))
  .add(sticky('## Étape 4 : garder les légendes en français\nLe filtre enlève les hashtags puis cherche des mots ou accents français. Si la légende n\'a que des hashtags : on regarde la langue du texte sur l\'image, puis la région du post et la langue de l\'auteur.', [], { name: 'Card 4 - Langue française', color: 5, width: 300, height: 200, position: [1020, 1000] }))
  .add(sticky('## Étape 5 : scores et classement\nvitesse = vues par heure ; surperformance = vues ÷ abonnés ; score = racine carrée de (vitesse × surperformance). Le classement est mis à jour par identifiant de post : pas de doublon.', [], { name: 'Card 5 - Scores', color: 5, width: 300, height: 200, position: [1360, 1000] }))
  .add(sticky('## Étape 6 : bilan et email\nLe bilan du lancement va dans l\'onglet Bilan (comptes, posts, carrousels gardés, échecs, crédits). Gemini rédige un commentaire, Gmail envoie le récapitulatif.', [], { name: 'Card 6 - Bilan et email', color: 5, width: 300, height: 200, position: [1700, 1000] }))