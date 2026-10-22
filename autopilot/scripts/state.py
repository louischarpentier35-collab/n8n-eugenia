#!/usr/bin/env python3
"""Autopilot task state, one file per session. Claude calls this at every phase change.

  state.py init    --session S --title T --project DIR [--brief PATH] [--mode direct|dev]
  state.py phase   --session S PHASE
  state.py ask     --session S "question"        (queue a question for Louis; work goes on)
  state.py answer  --session S Q1 "answer"
  state.py wait    --session S --reason "..."    (everything left depends on Louis: stop allowed)
  state.py resume  --session S
  state.py verdict --session S "À LIVRER|À CORRIGER|À REVOIR" --review PATH
  state.py finish  --session S
  state.py set     --session S KEY VALUE         (brief, doubts, mode, dashboard_note…)
  state.py show    --session S
  state.py list
  state.py dashboard-asset ID                    (after uploading dashboard.json; prints the old asset to delete)
  state.py config [KEY VALUE]                    (dashboard_url…)
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

DASHBOARD_HINT = "→ Mets à jour le tableau de bord autopilot (ligne de cette tâche)."


def fail(msg):
    print(f"ERREUR : {msg}", file=sys.stderr)
    sys.exit(1)


def need(session):
    task = common.load(session)
    if not task:
        fail(f"aucune tâche autopilot pour la session {session} (lance d'abord init)")
    return task


def main():
    if len(sys.argv) == 1:
        print(__doc__)
        return
    p = argparse.ArgumentParser()
    p.add_argument("cmd")
    p.add_argument("args", nargs="*")
    p.add_argument("--session")
    p.add_argument("--title")
    p.add_argument("--project")
    p.add_argument("--brief")
    p.add_argument("--mode", default="direct")
    p.add_argument("--reason")
    p.add_argument("--review")
    a = p.parse_args()

    if a.cmd == "list":
        print(json.dumps(common.all_tasks(), ensure_ascii=False, indent=2))
        return
    if a.cmd == "dashboard-asset":
        if len(a.args) != 1:
            fail("dashboard-asset <id de l'asset qui vient d'être chargé>")
        cfg = common.load_config()
        old = cfg.get("last_asset_id", "")
        cfg["last_asset_id"] = a.args[0]
        common.save_config(cfg)
        print(f"Ancien asset à supprimer : {old}" if old and old != a.args[0] else "Aucun ancien asset à supprimer.")
        return
    if a.cmd == "config":
        if len(a.args) == 2:
            cfg = common.load_config()
            cfg[a.args[0]] = a.args[1]
            common.save_config(cfg)
        print(json.dumps(common.load_config(), ensure_ascii=False, indent=2))
        return
    if not a.session:
        fail("--session est obligatoire")

    if a.cmd == "init":
        if not a.title or not a.project:
            fail("init demande --title et --project")
        if a.mode not in ("direct", "dev", "short"):
            fail("--mode : direct, dev ou short")
        # a short task needs no interview nor go: it starts building, but still needs a verdict
        task = {
            "session_id": a.session, "title": a.title, "project": a.project,
            "brief": a.brief or "", "mode": a.mode,
            "phase": "building" if a.mode == "short" else "interview",
            "questions": [], "waiting_reason": "", "verdict": "", "review": "",
            "doubts": "", "created_at": common.now(),
        }
        common.save(task)
        if a.mode == "short":
            print("Tâche courte suivie (phase building) : fais-la en mode doubt-driven-dev, puis "
                  "hostile-review en mode léger, puis verdict et finish. Pas de tableau de bord.")
        else:
            print(f"Tâche autopilot créée (phase interview). {DASHBOARD_HINT}")
        return

    task = need(a.session)

    if a.cmd == "phase":
        if len(a.args) != 1 or a.args[0] not in common.PHASES:
            fail(f"phase inconnue, choisis parmi : {', '.join(sorted(common.PHASES))}")
        if a.args[0] == "done":
            fail("pour terminer, utilise verdict puis finish")
        task["phase"] = a.args[0]
        task["waiting_reason"] = ""
        common.save(task)
        print(f"Phase : {task['phase']}. {DASHBOARD_HINT}")
    elif a.cmd == "ask":
        if len(a.args) != 1:
            fail('ask "question"')
        qid = f"Q{len(task['questions']) + 1}"
        task["questions"].append({"id": qid, "text": a.args[0], "asked_at": common.now(), "answer": ""})
        common.save(task)
        print(f"{qid} en file. Envoie une notification push à Louis, puis continue tout ce qui "
              f"n'en dépend pas. {DASHBOARD_HINT}")
    elif a.cmd == "answer":
        if len(a.args) != 2:
            fail('answer Q1 "réponse"')
        for q in task["questions"]:
            if q["id"] == a.args[0]:
                q["answer"] = a.args[1]
                break
        else:
            fail(f"question {a.args[0]} introuvable")
        common.save(task)
        print(f"Réponse enregistrée. {DASHBOARD_HINT}")
    elif a.cmd == "wait":
        task["waiting_reason"] = a.reason or "attend une décision de Louis"
        common.save(task)
        print(f"En attente de Louis : l'arrêt est autorisé. Envoie une notification push. {DASHBOARD_HINT}")
    elif a.cmd == "resume":
        task["waiting_reason"] = ""
        if task["phase"] in ("paused", "stalled"):
            task["phase"] = "building"
        common.save(task)
        print(f"Reprise (phase {task['phase']}). {DASHBOARD_HINT}")
    elif a.cmd == "verdict":
        if len(a.args) != 1 or a.args[0] not in common.VERDICTS:
            fail(f"verdict inconnu, choisis parmi : {', '.join(sorted(common.VERDICTS))}")
        if not a.review or not os.path.isfile(a.review):
            fail("--review doit pointer vers le fichier REVIEW.md écrit par hostile-review")
        task["verdict"], task["review"] = a.args[0], os.path.abspath(a.review)
        task["phase"] = "reviewing"
        common.save(task)
        print(f"Verdict : {task['verdict']}. {DASHBOARD_HINT}")
    elif a.cmd == "finish":
        if not task.get("verdict"):
            fail("pas de verdict de revue hostile : lance hostile-review puis verdict")
        task["phase"] = "done"
        task["waiting_reason"] = ""
        common.save(task)
        left = len(common.pending(task))
        print(f"Tâche terminée (verdict {task['verdict']}, {left} question(s) en attente). "
              f"Envoie la notification de fin à Louis. {DASHBOARD_HINT}")
    elif a.cmd == "set":
        if len(a.args) != 2 or a.args[0] in ("session_id", "phase", "verdict", "questions"):
            fail("set KEY VALUE (pas pour session_id, phase, verdict, questions)")
        task[a.args[0]] = a.args[1]
        common.save(task)
        print("OK")
    elif a.cmd == "show":
        print(json.dumps(task, ensure_ascii=False, indent=2))
    else:
        fail(f"commande inconnue : {a.cmd}")


if __name__ == "__main__":
    main()
