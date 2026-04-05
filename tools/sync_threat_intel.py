#!/usr/bin/env python3
"""Sync threat intelligence data from public sources for DFIR Simulator.

Downloads and caches:
- CISA Known Exploited Vulnerabilities (KEV) catalog
- MITRE ATT&CK Enterprise techniques (trimmed)

Rate-limited and respectful. Run periodically by developers, not at runtime.
Output is committed to assets/data/ for bundling with the game.

Usage:
    python3 tools/sync_threat_intel.py [--kev] [--attack] [--all]
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime

ASSETS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data')

# Rate limiting
REQUEST_DELAY = 2.0  # seconds between requests


def fetch_json(url: str, description: str) -> dict | list | None:
    """Fetch JSON from URL with rate limiting and error handling."""
    print(f"  Fetching {description}...")
    print(f"  URL: {url}")
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'DFIR-Simulator/1.0 (educational game; github.com/jbeley/dfir-godot)',
            'Accept': 'application/json',
        })
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode())
            print(f"  OK ({len(json.dumps(data))} bytes)")
            time.sleep(REQUEST_DELAY)
            return data
    except urllib.error.HTTPError as e:
        print(f"  HTTP Error {e.code}: {e.reason}")
        return None
    except urllib.error.URLError as e:
        print(f"  URL Error: {e.reason}")
        return None
    except Exception as e:
        print(f"  Error: {e}")
        return None


def sync_kev():
    """Download CISA Known Exploited Vulnerabilities catalog."""
    print("\n=== CISA KEV Catalog ===")
    url = "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"
    data = fetch_json(url, "CISA KEV catalog")
    if data is None:
        print("  FAILED - using empty dataset")
        data = {"vulnerabilities": []}

    vulns = data.get("vulnerabilities", [])

    # Trim to essential fields
    trimmed = []
    for v in vulns:
        trimmed.append({
            "cve_id": v.get("cveID", ""),
            "vendor": v.get("vendorProject", ""),
            "product": v.get("product", ""),
            "description": v.get("shortDescription", v.get("vulnerabilityName", "")),
            "date_added": v.get("dateAdded", ""),
            "due_date": v.get("dueDate", ""),
            "known_ransomware": v.get("knownRansomwareCampaignUse", "Unknown"),
        })

    output = {
        "description": "CISA Known Exploited Vulnerabilities catalog (trimmed)",
        "last_updated": datetime.utcnow().isoformat()[:10],
        "source": "https://www.cisa.gov/known-exploited-vulnerabilities-catalog",
        "count": len(trimmed),
        "vulnerabilities": trimmed,
    }

    path = os.path.join(ASSETS_DIR, "kev_mirror.json")
    with open(path, 'w') as f:
        json.dump(output, f, indent=2)
    print(f"  Saved {len(trimmed)} KEV entries to {path}")


def sync_attack():
    """Download MITRE ATT&CK Enterprise techniques."""
    print("\n=== MITRE ATT&CK Enterprise ===")
    url = "https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json"
    data = fetch_json(url, "ATT&CK Enterprise STIX bundle")
    if data is None:
        print("  FAILED - using empty dataset")
        data = {"objects": []}

    objects = data.get("objects", [])

    # Extract attack-pattern objects (techniques)
    techniques = []
    for obj in objects:
        if obj.get("type") != "attack-pattern":
            continue
        if obj.get("revoked", False) or obj.get("x_mitre_deprecated", False):
            continue

        # Get technique ID from external references
        tech_id = ""
        for ref in obj.get("external_references", []):
            if ref.get("source_name") == "mitre-attack":
                tech_id = ref.get("external_id", "")
                break

        if not tech_id:
            continue

        # Get tactics from kill chain phases
        tactics = []
        for phase in obj.get("kill_chain_phases", []):
            if phase.get("kill_chain_name") == "mitre-attack":
                tactics.append(phase.get("phase_name", ""))

        # Get data sources
        data_sources = []
        for ds in obj.get("x_mitre_data_sources", []):
            data_sources.append(ds)

        techniques.append({
            "technique_id": tech_id,
            "name": obj.get("name", ""),
            "description": obj.get("description", "")[:300],  # Trim long descriptions
            "tactics": tactics,
            "is_subtechnique": obj.get("x_mitre_is_subtechnique", False),
            "platforms": obj.get("x_mitre_platforms", []),
            "data_sources": data_sources[:5],  # Limit
            "detection": (obj.get("x_mitre_detection", "") or "")[:200],
        })

    techniques.sort(key=lambda t: t["technique_id"])

    output = {
        "description": "MITRE ATT&CK Enterprise techniques (trimmed for game use)",
        "last_updated": datetime.utcnow().isoformat()[:10],
        "source": "https://attack.mitre.org/",
        "count": len(techniques),
        "techniques": techniques,
    }

    path = os.path.join(ASSETS_DIR, "attack_techniques.json")
    with open(path, 'w') as f:
        json.dump(output, f, indent=2)
    print(f"  Saved {len(techniques)} techniques to {path}")


def main():
    os.makedirs(ASSETS_DIR, exist_ok=True)

    args = sys.argv[1:]
    if not args or '--all' in args:
        args = ['--kev', '--attack']

    print("DFIR Simulator - Threat Intel Sync")
    print(f"Date: {datetime.utcnow().isoformat()[:10]}")

    if '--kev' in args:
        sync_kev()
    if '--attack' in args:
        sync_attack()

    print("\nDone! Commit the updated files in assets/data/")


if __name__ == '__main__':
    main()
