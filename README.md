# Spectra

Spectra est une app Flutter desktop (Windows pour l'instant) qui crée une fenêtre overlay invisible lors du partage d'écran ou de la capture.

- 🖥️ Fonctionne sur Windows (Flutter desktop)
- 👻 Fenêtre visible localement mais masquée pour Zoom, Discord, Teams, OBS...
- 🔌 Utilise l'API native Windows `SetWindowDisplayAffinity`

## 🎯 Fonctionnalités futures possibles

- [ ] Filtrage par canal
- [ ] Recherche dans les messages
- [ ] Réponse aux messages
- [ ] Affichage des embeds et pièces jointes
- [ ] Affichage des images
- [ ] Notification sonore pour nouveaux messages
- [ ] Export de l'historique
- [ ] Statistiques des messages

## 📝 Notes techniques

- Les messages sont stockés en mémoire (max 100)
- Les messages du bot lui-même sont filtrés
- La liste s'affiche du plus récent au plus ancien
- L'écoute démarre automatiquement à la connexion
- L'écoute s'arrête automatiquement à la déconnexion
